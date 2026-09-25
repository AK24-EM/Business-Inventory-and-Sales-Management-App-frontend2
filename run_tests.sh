#!/bin/bash

# Test Runner Script for Store Inventory Management App
# This script provides convenient commands for running different types of tests

set -e

cd store_app

echo "🧪 Store Inventory Management - Test Runner"
echo "============================================="
echo ""

# Function to display help
show_help() {
    echo "Usage: ./run_tests.sh [option]"
    echo ""
    echo "Options:"
    echo "  all          Run all tests (default)"
    echo "  unit         Run unit tests only"
    echo "  models       Run model tests only"
    echo "  services     Run service tests only"
    echo "  coverage     Run tests with coverage report"
    echo "  watch        Run tests in watch mode"
    echo "  clean        Clean and run tests"
    echo "  help         Show this help message"
    echo ""
}

# Function to run all tests
run_all_tests() {
    echo "🚀 Running all tests..."
    flutter test
}

# Function to run unit tests
run_unit_tests() {
    echo "🔬 Running unit tests..."
    flutter test test/models/ test/services/
}

# Function to run model tests
run_model_tests() {
    echo "📦 Running model tests..."
    flutter test test/models/
}

# Function to run service tests
run_service_tests() {
    echo "⚙️ Running service tests..."
    flutter test test/services/
}

# Function to run tests with coverage
run_with_coverage() {
    echo "📊 Running tests with coverage..."
    flutter test --coverage
    
    # Check if genhtml is installed
    if command -v genhtml &> /dev/null; then
        echo "📈 Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        echo "✅ Coverage report generated at: coverage/html/index.html"
        
        # Open coverage report (macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        fi
    else
        echo "⚠️  genhtml not installed. Install lcov to generate HTML reports."
        echo "   macOS: brew install lcov"
        echo "   Linux: sudo apt-get install lcov"
    fi
}

# Function to run tests in watch mode
run_watch_mode() {
    echo "👀 Running tests in watch mode..."
    flutter test --watch
}

# Function to clean and run tests
run_clean_tests() {
    echo "🧹 Cleaning..."
    flutter clean
    flutter pub get
    echo ""
    run_all_tests
}

# Main script logic
case "${1:-all}" in
    all)
        run_all_tests
        ;;
    unit)
        run_unit_tests
        ;;
    models)
        run_model_tests
        ;;
    services)
        run_service_tests
        ;;
    coverage)
        run_with_coverage
        ;;
    watch)
        run_watch_mode
        ;;
    clean)
        run_clean_tests
        ;;
    help)
        show_help
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo "✅ Test execution completed!"
