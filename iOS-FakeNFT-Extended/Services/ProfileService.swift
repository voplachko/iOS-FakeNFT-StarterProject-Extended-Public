import Foundation

protocol ProfileService: Sendable {
    func loadProfile() async throws -> Profile
    func updateLikes(_ ids: [String]) async throws -> Profile
    /// nil — поле не изменилось и не отправляется.
    func updateProfile(
        name: String?,
        description: String?,
        website: String?,
        avatar: String?
    ) async throws -> Profile
}

actor ProfileServiceImpl: ProfileService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadProfile() async throws -> Profile {
        try await networkClient.send(request: ProfileRequest())
    }

    func updateLikes(_ ids: [String]) async throws -> Profile {
        try await send(ProfileUpdate(likes: ids))
    }

    func updateProfile(
        name: String?,
        description: String?,
        website: String?,
        avatar: String?
    ) async throws -> Profile {
        let update = ProfileUpdate(
            name: name,
            description: description,
            avatar: avatar,
            website: website
        )
        guard !update.formFields.isEmpty else {
            return try await loadProfile()
        }
        return try await send(update)
    }

    private func send(_ update: ProfileUpdate) async throws -> Profile {
        try await networkClient.send(request: ProfileUpdateRequest(update: update))
    }
}

#if DEBUG
/// Сервис для Preview: хранит профиль в памяти, сеть не трогает.
actor ProfileServiceMock: ProfileService {
    private var profile: Profile

    init(profile: Profile = .preview) {
        self.profile = profile
    }

    func loadProfile() async throws -> Profile {
        profile
    }

    func updateLikes(_ ids: [String]) async throws -> Profile {
        profile = Profile(
            id: profile.id,
            name: profile.name,
            avatar: profile.avatar,
            description: profile.description,
            website: profile.website,
            nfts: profile.nfts,
            likes: ids
        )
        return profile
    }

    func updateProfile(
        name: String?,
        description: String?,
        website: String?,
        avatar: String?
    ) async throws -> Profile {
        profile = Profile(
            id: profile.id,
            name: name ?? profile.name,
            avatar: avatar ?? profile.avatar,
            description: description ?? profile.description,
            website: website ?? profile.website,
            nfts: profile.nfts,
            likes: profile.likes
        )
        return profile
    }
}

extension Profile {
    static let preview = Profile(
        id: "1",
        name: "Joaquin Phoenix",
        avatar: "https://code.s3.yandex.net/landings-v2-ios-developer/space.PNG",
        description: "Дизайнер из Казани, люблю цифровое искусство и бейглы.",
        website: "https://practicum.yandex.ru/ios-developer",
        nfts: ["1", "2", "3"],
        likes: ["1"]
    )
}
#endif
