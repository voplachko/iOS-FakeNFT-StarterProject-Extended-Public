import Foundation

// Тестовые данные для Preview и моков. В Release-сборку не попадают.
#if DEBUG
extension Nft {
    static let previews: [Nft] = [
        Nft(
            id: "1",
            name: "Archie",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Archie/1.png")].compactMap { $0 },
            rating: 3,
            price: 1.78,
            author: "1"
        ),
        Nft(
            id: "2",
            name: "Ruby",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Ruby/1.png")].compactMap { $0 },
            rating: 5,
            price: 8.81,
            author: "1"
        ),
        Nft(
            id: "3",
            name: "Nacho Cheese Flamin Hot",
            images: [URL(string: "https://code.s3.yandex.net/Mobile/iOS/NFT/Pink/Nacho/1.png")].compactMap { $0 },
            rating: 1,
            price: 0.3,
            author: "1"
        )
    ]
}

extension NftCollection {
    static let previews: [NftCollection] = [
        NftCollection(
            id: "1",
            name: "Peach",
            cover: "https://code.s3.yandex.net/Mobile/iOS/NFT/Обложки_коллекций/Peach.png",
            nfts: ["1", "2", "3"],
            description: "Персиковый — как облака над закатным солнцем в океане. В этой коллекции совмещены трогательная нежность и живая игривость сказочных зефирных зверей.",
            author: "John Doe",
            website: "https://practicum.yandex.ru/ios-developer"
        ),
        NftCollection(
            id: "2",
            name: "Blue",
            cover: "https://code.s3.yandex.net/Mobile/iOS/NFT/Обложки_коллекций/Blue.png",
            nfts: ["1", "2"],
            description: "Голубая коллекция.",
            author: "2"
        )
    ]
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

extension Order {
    static let preview = Order(id: "1", nfts: ["1", "2", "3"])
}
#endif
