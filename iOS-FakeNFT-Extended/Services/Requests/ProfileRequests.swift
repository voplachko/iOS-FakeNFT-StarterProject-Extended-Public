import Foundation

private enum ProfileEndpoint {
    static let url = URL(string: "\(RequestConstants.baseURL)/api/v1/profile/1")
}

struct ProfileRequest: NetworkRequest {
    var endpoint: URL? { ProfileEndpoint.url }
}

struct ProfileUpdateRequest: NetworkRequest {
    let update: ProfileUpdate

    var endpoint: URL? { ProfileEndpoint.url }
    var httpMethod: HttpMethod { .put }
    var formFields: [String: FormValue]? { update.formFields }
}
