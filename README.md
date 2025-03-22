# vetconnect

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Database schema definiton:
vetconnect-d20f8 (database)
│
├── users/
│   └── {userId}/
│       ├── fullName: string
│       ├── email: string
│       ├── phoneNumber: string
│       ├── userType: string ('Farmer' | 'Veterinarian')
│       ├── createdAt: timestamp
│       └── roles?: {admin?: boolean}
│
├── veterinarians/
│   └── {vetId}/
│       ├── id: string
│       ├── name: string
│       ├── image: string
│       ├── specialization: string
│       ├── specializations: array<string>
│       ├── rating: number
│       ├── region: string
│       ├── charge: number
│       ├── isOnline: boolean
│       ├── lastSeen: timestamp
│       └── availability/
│           └── {slotId}/
│               ├── day: string
│               ├── startTime: string
│               ├── endTime: string
│               └── isAvailable: boolean
│
├── appointments/
│   └── {appointmentId}/
│       ├── farmerId: string
│       ├── vetId: string
│       ├── dateTime: timestamp
│       ├── type: string ('In-Person' | 'Video Call')
│       ├── status: string ('pending' | 'confirmed' | 'completed' | 'cancelled')
│       ├── animalType: string
│       ├── description: string
│       └── createdAt: timestamp
│
├── chats/
│   └── {chatId}/
│       ├── participants: array<string>
│       ├── lastMessage: string
│       ├── lastMessageTime: timestamp
│       └── messages/
│           └── {messageId}/
│               ├── senderId: string
│               ├── content: string
│               ├── timestamp: timestamp
│               ├── type: string ('text' | 'image')
│               └── status: string ('sent' | 'delivered' | 'read')
│
└── articles/
    └── {articleId}/
        ├── title: string
        ├── content: string
        ├── category: string ('Cattle Care' | 'Sheep Health' | 'Poultry Tips')
        ├── image: string
        ├── author: string
        └── publishedAt: timestamp
