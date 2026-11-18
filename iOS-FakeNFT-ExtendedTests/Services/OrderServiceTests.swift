import XCTest
@testable import iOS_FakeNFT_Extended

final class OrderServiceTests: XCTestCase {
    private let orderJSON = #"{"nfts": ["1", "2"], "id": "1"}"#

    func testLoadOrderSendsGet() async throws {
        let client = NetworkClientStub(response: orderJSON)
        let service = OrderServiceImpl(networkClient: client)

        let order = try await service.loadOrder()

        XCTAssertEqual(order.nfts, ["1", "2"])
        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .get)
        XCTAssertEqual(request.endpoint?.path, "/api/v1/orders/1")
    }

    func testUpdateOrderSendsNfts() async throws {
        let client = NetworkClientStub(response: orderJSON)
        let service = OrderServiceImpl(networkClient: client)

        _ = try await service.updateOrder(nfts: ["1", "2"])

        let requests = await client.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(request.formFields, ["nfts": .array(["1", "2"])])
    }

    func testClearOrderSendsEmptyArray() async throws {
        let client = NetworkClientStub(response: #"{"nfts": [], "id": "1"}"#)
        let service = OrderServiceImpl(networkClient: client)

        let order = try await service.updateOrder(nfts: [])

        XCTAssertTrue(order.nfts.isEmpty)
        let requests = await client.requests
        XCTAssertEqual(requests.first?.formFields, ["nfts": .array([])])
    }
}
