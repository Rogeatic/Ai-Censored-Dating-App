<h1>Blurrr Video Call App with WebRTC and AI Censoring</h1>
This application is a peer-to-peer video call platform built using WebRTC for real-time P2P communication. It features AI-powered censoring to automatically blur inappropriate content during video calls. The app is designed with a SwiftUI interface, and it supports user authentication via Google Sign-In.

# Features

- Real-time Video Communication: Utilizes WebRTC for low-latency, high-quality video streaming.
- AI Censoring: Detects and blurs inappropriate content using NSFWDetector.
- User Authentication: Users can sign in using their Google account.
- Profile Management: Users can view and update their profile information.
- Responsive UI: Built with SwiftUI, providing a modern and adaptive user interface.

# Project Structure
ContentView: The main entry point for the app. Handles user authentication, navigation, and the overall UI layout.

LoginView: A view for handling Google Sign-In. Displays a button for users to authenticate with their Google account.

VideoView: The main interface for video calls. Manages the local and remote video streams and applies the AI censoring.

LocalVideoView: A component that displays the local user's video feed.

RemoteVideoView: A component that displays the remote user's video feed, with AI censoring applied if necessary.

CameraPreviewView: A preview of the camera feed with AI censoring for NSFW content.

WebRTCHandler: Manages the WebRTC connection, including signaling, session setup, and data channels.

SignalingHandler: Manages the signaling process for setting up and maintaining WebRTC connections.

WebSocketHandler: Manages WebSocket connections for signaling.

# Installation

1. Clone the Repository

2. After cloning these files, podfiles must be set up for this project, and your own google sign in auth-key might be needed. 

3. Go to the Google Developer Console.

4. Create a new project and configure the OAuth 2.0 client IDs.

5. Download the GoogleService-Info.plist file and add it to your Xcode project.

7. Ensure you have a compatible iOS device, simulators only allow audio calls.

8. Build and run the app on device.

# Usage
1. Sign In: Launch the app and sign in with your Google account.

2. Start a Call: Once signed in, you can initiate a video call.

3. AI Censoring: The app will automatically blur any detected inappropriate content.

*The AI censoring feature uses NSFWDetector to analyze video frames for inappropriate content. If such content is detected with a confidence level above 90%, the video is blurred.*

# Required Packages: 
- Starscream 4.0.4

- WebRTC 125.0.0

- pod 'NSFWDetector' - July 2024

- pod 'GoogleSignIn' - July 2024

*pods may no longer be necessary*

# Contribution

Contributions are welcome! Please fork the repository and submit a pull request for any improvements or bug fixes.

# Acknowledgements

WebRTC: The core technology enabling real-time communication.

NSFWDetector: The AI component used for detecting inappropriate content.

SwiftUI: The framework used to build the user interface.

The documentation and examples in this demo app was a great help: https://github.com/stasel/WebRTC-iOS 

*I would love to hear feature requests! I am aware of a memory leak involving navigating between the video call screen and join screen. The biggest issue currently is that video calls can only be joined once unless the app is closed and reopened.*


# Example of the waiting screen \(tricked  into bluring\):

<img src="https://github.com/Rogeatic/Ai-Censored-Dating-App/blob/main/IMG_7613.PNG?raw=true" alt="Screenshot" width="400">
