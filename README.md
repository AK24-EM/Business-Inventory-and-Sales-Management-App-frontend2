# Business Inventory and Sales Management App

A comprehensive Flutter-based inventory and sales management system with role-based access control.

## Features

- 🔐 **Role-Based Authentication** (Owner, Manager, Employee)
- 📦 **Inventory Management** - Track products across multiple stores
- 💰 **Sales & POS System** - Complete point-of-sale functionality
- 👥 **Customer Management** - Track customer purchases and loyalty
- 📊 **Analytics Dashboard** - Real-time sales and inventory analytics
- 🎉 **Festival Management** - Schedule special events and promotions
- 🔔 **Notifications** - Real-time updates and alerts

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Firebase** - Authentication and cloud services
- **Material Design 3** - Modern UI/UX

### Backend
- **Python FastAPI** - High-performance REST API
- **SQLite** - Local database
- **Firebase Admin SDK** - User management

## Project Structure

```
store_invemtory_mamanagement/
├── store_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── screens/    # UI screens (owner, manager, employee)
│   │   ├── services/   # API and auth services
│   │   ├── models/     # Data models
│   │   ├── config/     # App configuration
│   │   └── routing/    # Navigation routing
│   └── pubspec.yaml
├── backend/            # Python FastAPI backend
│   ├── app/
│   │   ├── models/     # Database models
│   │   ├── routes/     # API endpoints
│   │   └── schemas/    # Pydantic schemas
│   └── requirements.txt
├── seed/               # Database seeding scripts
└── functions/          # Cloud functions

```

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Python 3.8+
- Firebase account
- Node.js (for cloud functions)

### Frontend Setup

1. Navigate to the Flutter app:
```bash
cd store_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` (Android)
   - Add your `GoogleService-Info.plist` (iOS)
   - Update `lib/utils/firebase_options.dart`

4. Run the app:
```bash
flutter run
```

### Backend Setup

1. Navigate to backend:
```bash
cd backend
```

2. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the server:
```bash
uvicorn app.main:app --reload
```

## User Roles

### Owner
- Complete system access
- Manage stores and users
- View analytics across all stores
- Configure festival promotions

### Manager
- Store-level management
- Inventory and sales oversight
- Staff coordination
- Store analytics

### Employee
- Point of sale operations
- Customer management
- Inventory viewing
- Daily sales tasks

## API Documentation

Once the backend is running, access the interactive API docs at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Screenshots

_Coming soon_

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue on GitHub.
