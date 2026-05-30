FYI 


⸻

📱 100 Acts App – User Flow

1. App Launch
	•	User opens the app
	•	App checks:
	•	Authentication status
	•	Location permission

⸻

2. Authentication
	•	If not logged in:
	•	User signs up / logs in
	•	If logged in:
	•	Navigate to Home screen

⸻

3. Home Screen
	•	User sees:
	•	“Start an Act” button
	•	Progress (number of acts completed)
	•	Recent activities (optional)

⸻

4. Start an Act
	•	User taps “Start an Act”

⸻

5. Select Action Type
	•	User selects one category:
	•	Tree / Mangrove
	•	Wildlife
	•	Recycling
	•	Litter Cleanup
	•	App stores selected category
	•	Navigate to Capture screen

⸻

6. Location Check
	•	App checks location permission:
	•	If granted → proceed
	•	If denied →
	•	Disable capture
	•	Show message: “Location access is required”
	•	Provide “Enable Location” button

⸻

7. Capture Screen
	•	App fetches:
	•	High-accuracy GPS (lat, long, accuracy)
	•	UI shows:
	•	Selected action
	•	Camera view
	•	User taps Capture

⸻

8. Data Capture
	•	App collects:
	•	Photo / Video
	•	Latitude & Longitude
	•	GPS accuracy
	•	Timestamp:
	•	Device time (temporary)
	•	Server time (added on backend)

⸻

9. Additional Input (if required)
	•	For Litter Cleanup:
	•	User selects garbage type (e.g., plastic, cans, etc.)
	•	Other categories:
	•	No extra input

⸻

10. Save Action

If Online:
	•	Upload media to server
	•	Send data:
	•	category
	•	media
	•	location (lat, long, accuracy)
	•	Backend adds server timestamp
	•	Save as “synced”

If Offline:
	•	Save data locally with status “pending”
	•	Show “Pending Sync” status

⸻

11. Sync Process
	•	When internet is available:
	•	Pending records are uploaded automatically
	•	Backend adds server timestamp
	•	Status updated to “synced”

⸻

12. Confirmation
	•	User sees:
	•	“Act Recorded Successfully”
	•	Updated act count

⸻

13. Progress Tracking
	•	User can view:
	•	Total acts completed
	•	Badge after 50 acts

⸻

14. Map View (Future)
	•	App displays:
	•	Acts as map pins using stored lat/long
	•	Clustered view for multiple acts

⸻

15. Social Sharing (Optional)
	•	User can:
	•	Share photo/video to social media
	•	Use hashtags:
	•	#100ActsMovement
	•	#100ActsOfKindness