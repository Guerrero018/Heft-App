# Heft 

A comprehensive fitness and workout management platform. 

### Overview
**Heft** is a dual-component application designed to help users track their fitness routines, personal progress, and workout statistics. It features a robust backend for data management and a modern, high-performance mobile/web frontend.

---

### Project Structure
The repository is organized as follows:
- **[/backend](file:///c:/Users/izang/OneDrive/Escritorio/Escritorio/Projects/Heft/backend)**: Django REST Framework API for data persistence and business logic.
- **[/frontend](file:///c:/Users/izang/OneDrive/Escritorio/Escritorio/Projects/Heft/frontend)**: Flutter mobile/web application with a sleek, fitness-oriented design.

---

### Tech Stack
- **Backend**: Python, Django, PostgreSQL.
- **Frontend**: Dart, Flutter, Riverpod (State Management).
- **Other**: Git, Docker (optional).

---

### Getting Started

#### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run migrations:
   ```bash
   python manage.py migrate
   ```
5. Start the server:
   ```bash
   python manage.py runserver
   ```

#### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

*Created by [Guerrero018](https://github.com/Guerrero018)*
