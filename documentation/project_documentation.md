# Project Documentation: Car Pool Application

## 1. Overview
This is a Flutter-based Car Pool mobile application designed for sharing rides.

## 2. Technologies Used

### Frontend & UI
- **Flutter**: Cross-platform mobile framework
- **State Management**: Provider
- **UI Components**: 
  - flutter_rating_bar
  - shimmer
  - flutter_svg

### Backend & Database
- **Firebase**:
  - `firebase_core`: Core SDK
  - `firebase_auth`: User authentication
  - `cloud_firestore`: Document database for structured data (e.g., rides, users, reviews)
  - `firebase_messaging`: Push notifications
  - `firebase_database`: Realtime Database
  - `firebase_storage`: File storage for images (e.g., user profiles)

### Maps & Location
- **Google Maps Flutter**: For map display
- **Geolocator**: For device location services
- **Geocoding**: For location searching/address conversion

### Other Services
- **HTTP/Dio**: For API communication
- **Image Picker & Cached Network Image**: For user profiles and images
- **Razorpay Flutter**: For payments
- **URL Launcher**: For external links
- **Intl**: For date/time formatting
- **Shared Preferences**: For local storage
- **UUID**: For ID generation

## 3. Database Schema Overview (Models)

### RideModel (Firestore)
- Represents a ride offering/request.
- Includes driver details, pickup/drop locations (lat/lng), timing, available seats, fare, and status.

### UserModel
- (To be explored further)

## 4. Known Issues & TODOs

### Identified Issues
1. **Home Screen**: Currently static. Navigation actions for "Find a Ride", "Create a Ride", and "Cab Sharing" are not implemented.
2. **General**: Need to conduct a thorough review to identify further issues, as described by the user.

### Pending Tasks
- Implement navigation for action cards on the home screen.
- Review and fix other unidentified issues.
