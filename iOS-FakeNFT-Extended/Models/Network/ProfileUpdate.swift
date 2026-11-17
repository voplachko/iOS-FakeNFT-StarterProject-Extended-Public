import Foundation

/// Изменения профиля для PUT /api/v1/profile/1. nil — поле не меняется и не отправляется.
struct ProfileUpdate: Sendable, Equatable {
    var name: String?
    var description: String?
    var avatar: String?
    var website: String?
    var likes: [String]?

    var formFields: [String: FormValue] {
        var fields: [String: FormValue] = [:]
        if let name { fields["name"] = .string(name) }
        if let description { fields["description"] = .string(description) }
        if let avatar { fields["avatar"] = .string(avatar) }
        if let website { fields["website"] = .string(website) }
        if let likes { fields["likes"] = .array(likes) }
        return fields
    }
}
