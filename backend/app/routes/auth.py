import bcrypt
import logging
import os
from datetime import datetime, timedelta
from typing import Optional

import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User, UserRole
from app.schemas.user import UserCreate, UserLogin, UserResponse, TokenResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["Authentication"])

# ── Firebase Admin SDK initialisation ────────────────────────────────────────
# On Cloud Run the default service account has the necessary IAM permissions,
# so no explicit credential file is needed.  When running locally, set
# GOOGLE_APPLICATION_CREDENTIALS to the path of the service-account JSON.
def _init_firebase() -> bool:
    """Initialise Firebase Admin SDK once. Returns True if successful."""
    if firebase_admin._apps:
        return True  # already initialised
    try:
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            # On Cloud Run: default service account + explicit project id so
            # verify_id_token can resolve the Firebase project.
            firebase_admin.initialize_app(
                options={"projectId": settings.GCP_PROJECT_ID}
            )
        return True
    except Exception as exc:
        logger.warning("Firebase Admin SDK init failed: %s", exc)
        return False

_FIREBASE_AVAILABLE = _init_firebase()

# ── OAuth2 scheme (reads Bearer token from Authorization header) ──────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


# ── Password helpers ──────────────────────────────────────────────────────────
def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"), hashed_password.encode("utf-8")
        )
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


# ── Custom JWT helpers (used by /auth/login, kept for backward compat) ────────
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def _user_from_custom_jwt(token: str, db: Session) -> Optional[User]:
    """Try to decode our own HS256 JWT. Returns None if it's not our token."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if not user_id:
            return None
        return db.query(User).filter(User.id == user_id).first()
    except JWTError:
        return None


def _user_from_firebase_token(token: str, db: Session) -> Optional[User]:
    """
    Verify a Firebase ID token using the Admin SDK.
    Looks up the backend User record by firebase_uid (preferred) or email.
    Auto-creates a User row on first login if the Firebase UID is verified
    but no matching DB record is found (handles users created only via Firebase).
    """
    if not _FIREBASE_AVAILABLE:
        return None
    try:
        decoded = firebase_auth.verify_id_token(token)
        uid: str = decoded.get("uid", "")
        email: str = decoded.get("email", "")
        display_name: str = decoded.get("name", email.split("@")[0] if email else "User")
        claim_role = decoded.get("role")
        try:
            mapped_role = UserRole(claim_role) if claim_role else UserRole.employee
        except ValueError:
            mapped_role = UserRole.employee

        # 1. Try lookup by firebase_uid column (fastest path after first login)
        user = db.query(User).filter(User.firebase_uid == uid).first()
        if user:
            return user

        # 2. Fall back to email match and bind the firebase_uid
        if email:
            user = db.query(User).filter(User.email == email).first()
            if user:
                try:
                    user.firebase_uid = uid
                    db.commit()
                except Exception:
                    db.rollback()
                return user

        # 3. Auto-create a backend User row for verified Firebase users who
        #    don't yet exist in the DB (e.g. created via Firebase Console).
        #    Defaults to 'employee' role — an admin can promote later.
        if uid and email:
            try:
                new_user = User(
                    firebase_uid=uid,
                    name=display_name,
                    email=email,
                    phone="",
                    hashed_password="",          # no password needed — Firebase auth
                    role=mapped_role,
                    is_active=True,
                )
                db.add(new_user)
                db.commit()
                db.refresh(new_user)
                logger.info("Auto-created backend user for Firebase UID %s (%s)", uid, email)
                return new_user
            except Exception as create_exc:
                db.rollback()
                logger.warning("Failed to auto-create user for %s: %s", email, create_exc)

        return None
    except Exception as exc:
        logger.warning("Firebase token verification failed: %s", exc)
        return None


# ── Core dependency ───────────────────────────────────────────────────────────
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    Accepts EITHER:
      • A Firebase ID token (issued by Firebase Auth on the client)  ← primary
      • A custom HS256 JWT issued by POST /auth/login                ← legacy

    This dual-accept strategy lets the Flutter app migrate to Firebase tokens
    without requiring a simultaneous backend + app deployment.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # ── Try Firebase ID token first ──────────────────────────────────────────
    user = _user_from_firebase_token(token, db)

    # ── Fall back to our own JWT ─────────────────────────────────────────────
    if user is None:
        user = _user_from_custom_jwt(token, db)

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive or non-existent user",
        )
    return user


def require_roles(allowed_roles: list[UserRole]):
    def role_checker(current_user: User = Depends(get_current_user)):
        if (
            current_user.role not in allowed_roles
            and current_user.role != UserRole.admin
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return current_user

    return role_checker


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/register", response_model=UserResponse)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=user_in.name,
        email=user_in.email,
        phone=user_in.phone,
        hashed_password=get_password_hash(user_in.password),
        role=user_in.role,
        assigned_store_id=user_in.assigned_store_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """
    Legacy email/password login that issues a custom HS256 JWT.
    Still supported so existing integrations keep working.
    """
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated"
        )

    user.last_login = datetime.utcnow()
    db.commit()

    token = create_access_token(
        data={"sub": user.id, "role": user.role.value, "email": user.email}
    )
    return TokenResponse(
        access_token=token, token_type="bearer", user=UserResponse.from_orm(user)
    )


@router.post("/token", response_model=TokenResponse)
def login_form(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )

    token = create_access_token(
        data={"sub": user.id, "role": user.role.value, "email": user.email}
    )
    return TokenResponse(
        access_token=token, token_type="bearer", user=UserResponse.from_orm(user)
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.get("/users", response_model=list[UserResponse])
def list_users(
    store_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles([UserRole.owner, UserRole.admin, UserRole.manager])
    ),
):
    query = db.query(User)
    if store_id:
        query = query.filter(User.assigned_store_id == store_id)
    return query.all()
