import XCTest
@testable import iOS_FakeNFT_Extended

final class ProfileServiceTests: XCTestCase {
    private let profileJSON = """
    {"name": "Имя", "avatar": "", "description": "", "website": "", "nfts": [], "likes": ["1", "2"], "id": "1"}
    """

    func testLoadProfileSendsGet() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        let profile = try await service.loadProfile()

        XCTAssertEqual(profile.likes, ["1", "2"])
        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .get)
        XCTAssertEqual(request.endpoint?.path, "/api/v1/profile/1")
        XCTAssertNil(request.formFields)
    }

    func testUpdateLikesSendsOnlyLikes() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateLikes(["1", "2"])

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["likes": .array(["1", "2"])])
    }

    func testUpdateProfileSendsOnlyChangedFields() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateProfile(name: "Новое имя", description: nil, website: "https://ya.ru", avatar: nil)

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["name": .string("Новое имя"), "website": .string("https://ya.ru")])
    }

    func testUpdateProfileWithoutChangesOnlyLoads() async throws {
        let client = NetworkClientStub(response: profileJSON)
        let service = ProfileServiceImpl(networkClient: client)

        _ = try await service.updateProfile(name: nil, description: nil, website: nil, avatar: nil)

        let requests = await client.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.httpMethod, .get)
    }
}
