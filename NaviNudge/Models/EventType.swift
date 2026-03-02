import Foundation

/// The type of event associated with a destination, used to calculate arrival buffer time.
enum EventType: String, CaseIterable, Codable, Identifiable {
  case jobInterview   = "job_interview"
  case importantMeeting = "important_meeting"
  case medicalAppointment = "medical_appointment"
  case workMeeting    = "work_meeting"
  case casualLunch    = "casual_lunch"
  case socialEvent    = "social_event"
  case errand         = "errand"
  case none           = "none"

  var id: String { rawValue }

  /// Human-readable label shown in the UI.
  var label: String {
    switch self {
    case .jobInterview:        return "Job Interview"
    case .importantMeeting:    return "Important Meeting"
    case .medicalAppointment:  return "Medical Appointment"
    case .workMeeting:         return "Work Meeting"
    case .casualLunch:         return "Casual Lunch"
    case .socialEvent:         return "Social Event"
    case .errand:              return "Errand"
    case .none:                return "None"
    }
  }

  /// SF Symbol name representing the event type.
  var symbol: String {
    switch self {
    case .jobInterview:        return "briefcase.fill"
    case .importantMeeting:    return "exclamationmark.circle.fill"
    case .medicalAppointment:  return "cross.case.fill"
    case .workMeeting:         return "person.2.fill"
    case .casualLunch:         return "fork.knife"
    case .socialEvent:         return "party.popper.fill"
    case .errand:              return "cart.fill"
    case .none:                return "location.fill"
    }
  }

  /// Base arrival buffer in minutes for this event type, regardless of traffic.
  var baseBufferMinutes: Int {
    switch self {
    case .jobInterview:        return 30
    case .importantMeeting:    return 20
    case .medicalAppointment:  return 15
    case .workMeeting:         return 15
    case .casualLunch:         return 5
    case .socialEvent:         return 5
    case .errand:              return 5
    case .none:                return 0
    }
  }
}
