import Foundation

enum Templates {

    struct Context {
        let name: String        // "Transfers"
        let module: String      // "TransfersMicroUI"
        let nameLower: String   // "transfers"
        let authorName: String
        let authorEmail: String
        let icon: String
        let tileDesc: String
        let date: String

        init(name: String, authorName: String, authorEmail: String, icon: String, tileDesc: String) {
            self.name = name
            self.module = "\(name)MicroUI"
            self.nameLower = name.lowercased()
            self.authorName = authorName
            self.authorEmail = authorEmail
            self.icon = icon
            self.tileDesc = tileDesc
            self.date = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: Date())
            }()
        }
    }

    // MARK: - Package.swift

    static func packageSwift(_ c: Context) -> String {
        """
        // swift-tools-version: 5.9
        // \(c.module) — Created by \(c.authorName) <\(c.authorEmail)> on \(c.date)

        import PackageDescription

        let package = Package(
            name: "\(c.module)",
            platforms: [.iOS(.v17)],
            products: [
                .library(name: "\(c.module)", targets: ["\(c.module)"])
            ],
            dependencies: [
                .package(path: "../MicroUICore")
            ],
            targets: [
                .target(
                    name: "\(c.module)",
                    dependencies: ["MicroUICore"],
                    resources: [.process("Mocks/JSON")]
                ),
                .testTarget(
                    name: "\(c.module)Tests",
                    dependencies: ["\(c.module)"]
                )
            ]
        )
        """
    }

    // MARK: - Config

    static func config(_ c: Context) -> String {
        """
        import MicroUICore
        import Factory

        public struct \(c.module)Config: MicroUIRegistration {

            public init() {}

            public func registerMicroUI() {
                Container.shared.\(c.nameLower)TileBuilder.register {
                    \(c.module)TileBuilder()
                }
                Container.shared.\(c.nameLower)ScreenBuilder.register {
                    \(c.module)ScreenBuilder()
                }

                // Register deep link handler
                OwlsDeepLinkRouter.shared.register(\(c.module)DeepLinkHandler())

                // Register mock provider — available in Debug Drawer (DEBUG only)
                #if DEBUG
                OwlsMockRegistry.shared.register(\(c.module)MockProvider())
                #endif
            }
        }
        """
    }

    // MARK: - Domain Model

    static func domainModel(_ c: Context) -> String {
        """
        import Foundation

        struct \(c.name)Item: Identifiable, Hashable, Codable, Sendable {
            let id: String
            let title: String
            let subtitle: String
            let iconName: String
            let createdAt: Date

            static let mock: [\(c.name)Item] = [
                \(c.name)Item(id: "1", title: "Sample \(c.name) 1", subtitle: "Description for item 1", iconName: "star.fill", createdAt: Date()),
                \(c.name)Item(id: "2", title: "Sample \(c.name) 2", subtitle: "Description for item 2", iconName: "heart.fill", createdAt: Date()),
                \(c.name)Item(id: "3", title: "Sample \(c.name) 3", subtitle: "Description for item 3", iconName: "bolt.fill", createdAt: Date()),
            ]
        }
        """
    }

    // MARK: - Localized Strings

    static func localizedStrings(_ c: Context) -> String {
        """
        import Foundation
        import MicroUICore

        enum \(c.name)Strings {

            static var screenTitle: String {
                owlsLocalized("\(c.nameLower).title", comment: "\(c.name)")
            }

            static var detailTitle: String {
                owlsLocalized("\(c.nameLower).detail.title", comment: "Details")
            }

            static var loadingMessage: String {
                owlsLocalized("\(c.nameLower).loading", comment: "Loading \(c.nameLower)…")
            }

            static var retryButton: String {
                owlsLocalized("common.retry", comment: "Retry")
            }

            static var closeButton: String {
                owlsLocalized("common.close", comment: "Close")
            }

            static var deleteAction: String {
                owlsLocalized("\(c.nameLower).delete", comment: "Delete")
            }

            static var emptyTitle: String {
                owlsLocalized("\(c.nameLower).empty.title", comment: "No \(c.name) Yet")
            }

            static var emptyDescription: String {
                owlsLocalized("\(c.nameLower).empty.description", comment: "Items will appear here once available.")
            }

            static var tileTitle: String {
                owlsLocalized("\(c.nameLower).tile.title", comment: "\(c.name)")
            }

            static var tileDescription: String {
                owlsLocalized("\(c.nameLower).tile.description", comment: "\(c.tileDesc)")
            }

            static var errorTitle: String {
                owlsLocalized("\(c.nameLower).error.title", comment: "Something went wrong")
            }
        }
        """
    }

    // MARK: - DataSource

    static func dataSource(_ c: Context) -> String {
        """
        import Foundation
        import MicroUICore

        protocol \(c.name)DataSource: Sendable {
            func fetchAll() async throws -> [\(c.name)Item]
            func fetchDetail(id: String) async throws -> \(c.name)Item
            func create(name: String) async throws -> \(c.name)Item
            func delete(id: String) async throws
        }

        // MARK: - Mock

        struct Mock\(c.name)DataSource: \(c.name)DataSource {

            func fetchAll() async throws -> [\(c.name)Item] {
                try await Task.sleep(for: .milliseconds(500))
                return \(c.name)Item.mock
            }

            func fetchDetail(id: String) async throws -> \(c.name)Item {
                try await Task.sleep(for: .milliseconds(300))
                guard let item = \(c.name)Item.mock.first(where: { $0.id == id }) else {
                    throw OwlsNetworkError.notFound
                }
                return item
            }

            func create(name: String) async throws -> \(c.name)Item {
                try await Task.sleep(for: .milliseconds(400))
                return \(c.name)Item(id: UUID().uuidString, title: name, subtitle: "Newly created", iconName: "plus.circle.fill", createdAt: Date())
            }

            func delete(id: String) async throws {
                try await Task.sleep(for: .milliseconds(300))
            }
        }

        // MARK: - Live (swap Mock → Live when API is ready)
        //
        // final class Live\(c.name)DataSource: OwlsBaseService, \(c.name)DataSource {
        //     func fetchAll() async throws -> [\(c.name)Item] {
        //         try await request(\(c.name)API.list)
        //     }
        //     func fetchDetail(id: String) async throws -> \(c.name)Item {
        //         try await request(\(c.name)API.detail(id: id))
        //     }
        //     func create(name: String) async throws -> \(c.name)Item {
        //         try await request(\(c.name)API.create(\(c.name)CreateRequest(name: name)))
        //     }
        //     func delete(id: String) async throws {
        //         try await requestVoid(\(c.name)API.delete(id: id))
        //     }
        // }
        """
    }

    // MARK: - API Routes

    static func apiRoutes(_ c: Context) -> String {
        """
        import Foundation
        import MicroUICore

        enum \(c.name)API: OwlsAPIRoute {

            case list
            case detail(id: String)
            case create(\(c.name)CreateRequest)
            case update(id: String, \(c.name)UpdateRequest)
            case delete(id: String)

            var path: String {
                switch self {
                case .list:
                    "/v1/\(c.nameLower)"
                case .detail(let id):
                    "/v1/\(c.nameLower)/\\(id)"
                case .create:
                    "/v1/\(c.nameLower)"
                case .update(let id, _):
                    "/v1/\(c.nameLower)/\\(id)"
                case .delete(let id):
                    "/v1/\(c.nameLower)/\\(id)"
                }
            }

            var method: HTTPMethod {
                switch self {
                case .list, .detail: .get
                case .create: .post
                case .update: .put
                case .delete: .delete
                }
            }

            var body: Data? {
                switch self {
                case .create(let payload): Self.encode(payload)
                case .update(_, let payload): Self.encode(payload)
                default: nil
                }
            }
        }

        struct \(c.name)CreateRequest: Encodable, Sendable {
            let name: String
        }

        struct \(c.name)UpdateRequest: Encodable, Sendable {
            let name: String
        }
        """
    }

    // MARK: - Service Dispatcher

    static func serviceDispatcher(_ c: Context) -> String {
        """
        import Foundation

        struct \(c.name)ServiceDispatcher: Sendable {
            let dataSource: \(c.name)DataSource

            func fetchAll() async throws -> [\(c.name)Item] {
                try await dataSource.fetchAll()
            }

            func fetchDetail(id: String) async throws -> \(c.name)Item {
                try await dataSource.fetchDetail(id: id)
            }

            func create(name: String) async throws -> \(c.name)Item {
                try await dataSource.create(name: name)
            }

            func delete(id: String) async throws {
                try await dataSource.delete(id: id)
            }
        }
        """
    }

    // MARK: - Repository

    static func repository(_ c: Context) -> String {
        """
        import Foundation

        protocol \(c.name)Repository: Sendable {
            func loadAll() async throws -> [\(c.name)Item]
            func loadDetail(id: String) async throws -> \(c.name)Item
            func create(name: String) async throws -> \(c.name)Item
            func delete(id: String) async throws
        }

        struct Default\(c.name)Repository: \(c.name)Repository {
            private let dispatcher: \(c.name)ServiceDispatcher

            init(dispatcher: \(c.name)ServiceDispatcher) {
                self.dispatcher = dispatcher
            }

            func loadAll() async throws -> [\(c.name)Item] {
                try await dispatcher.fetchAll()
            }

            func loadDetail(id: String) async throws -> \(c.name)Item {
                try await dispatcher.fetchDetail(id: id)
            }

            func create(name: String) async throws -> \(c.name)Item {
                try await dispatcher.create(name: name)
            }

            func delete(id: String) async throws {
                try await dispatcher.delete(id: id)
            }
        }
        """
    }

    // MARK: - ViewModel

    static func viewModel(_ c: Context) -> String {
        """
        import Foundation
        import Observation

        @Observable
        final class \(c.module)ViewModel {

            private(set) var items: [\(c.name)Item] = []
            private(set) var isLoading = false
            private(set) var errorMessage: String?
            var isCreateSheetPresented = false

            private let repository: \(c.name)Repository

            init(repository: \(c.name)Repository) {
                self.repository = repository
            }

            // MARK: - Load

            func load() async {
                isLoading = true
                errorMessage = nil
                do {
                    items = try await repository.loadAll()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }

            // MARK: - Create

            func createItem(name: String) async {
                do {
                    let newItem = try await repository.create(name: name)
                    items.insert(newItem, at: 0)
                    isCreateSheetPresented = false
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            // MARK: - Delete

            func deleteItem(id: String) async {
                do {
                    try await repository.delete(id: id)
                    items.removeAll { $0.id == id }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        """
    }

    // MARK: - Screen View

    static func screenView(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        // MARK: - Main Screen (presented as fullScreenCover from dashboard)

        struct \(c.module)View: View {

            @State private var viewModel: \(c.module)ViewModel
            @Injected(\\.\(c.nameLower)NavigationCoordinator) private var coordinator
            @State private var path = NavigationPath()

            init(viewModel: \(c.module)ViewModel) {
                _viewModel = State(initialValue: viewModel)
            }

            var body: some View {
                NavigationStack(path: $path) {
                    Group {
                        if viewModel.isLoading {
                            OwlsLoadingView("Loading \(c.nameLower)…")
                        } else if let error = viewModel.errorMessage {
                            OwlsEmptyState(
                                icon: "exclamationmark.triangle",
                                title: "Something went wrong",
                                description: error,
                                actionTitle: "Retry"
                            ) { Task { await viewModel.load() } }
                        } else if viewModel.items.isEmpty {
                            OwlsEmptyState(
                                icon: "tray",
                                title: "No \(c.name) Yet",
                                description: "Items will appear here once available."
                            )
                        } else {
                            itemList
                        }
                    }
                    .navigationTitle("\(c.name)")
                    // MARK: Navigation — push to detail screen
                    .navigationDestination(for: \(c.module)Router.self) { route in
                        route.resolveViewForRoute()
                    }
                    .toolbar {
                        // MARK: Dismiss — closes fullScreenCover
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { coordinator.dismiss() }
                        }
                        // MARK: Sheet — opens create form as sheet
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                viewModel.isCreateSheetPresented = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    // MARK: Sheet presentation
                    .sheet(isPresented: $viewModel.isCreateSheetPresented) {
                        \(c.name)CreateSheet(viewModel: viewModel)
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }
                }
                .task { await viewModel.load() }
            }

            // MARK: - List (tapping a row pushes detail screen)

            private var itemList: some View {
                List {
                    ForEach(viewModel.items) { item in
                        Button {
                            // Navigation: push detail screen
                            path.append(\(c.module)Router.detail(item))
                        } label: {
                            HStack(spacing: OwlsSpacing.md) {
                                Image(systemName: item.iconName)
                                    .font(.title3)
                                    .foregroundStyle(OwlsColor.primary)
                                    .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: OwlsSpacing.xxs) {
                                    Text(item.title)
                                        .font(OwlsTypography.headline)
                                    Text(item.subtitle)
                                        .font(OwlsTypography.caption)
                                        .foregroundStyle(OwlsColor.secondaryLabel)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(OwlsColor.secondaryLabel)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = viewModel.items[index]
                            Task { await viewModel.deleteItem(id: item.id) }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        """
    }

    // MARK: - Create Sheet

    static func createSheet(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        // MARK: - Create Sheet (presented as .sheet from main screen)

        struct \(c.name)CreateSheet: View {

            @State private var name = ""
            @State private var isSaving = false
            @Environment(\\.dismiss) private var dismiss
            var viewModel: \(c.module)ViewModel

            var body: some View {
                NavigationStack {
                    Form {
                        Section("New \(c.name)") {
                            OwlsTextField(
                                "Name",
                                placeholder: "Enter name",
                                text: $name
                            )
                        }

                        if let error = viewModel.errorMessage {
                            Section {
                                OwlsAlert(.error, message: error)
                            }
                        }
                    }
                    .navigationTitle("Create \(c.name)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                isSaving = true
                                Task {
                                    await viewModel.createItem(name: name)
                                    isSaving = false
                                }
                            }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        }
                    }
                }
            }
        }
        """
    }

    // MARK: - Tile View

    static func tileView(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        struct \(c.name)TileView: View {

            @Injected(\\.\(c.nameLower)NavigationCoordinator) private var coordinator

            var body: some View {
                Button { coordinator.present() } label: {
                    VStack(spacing: OwlsSpacing.sm) {
                        Image(systemName: "\(c.icon)")
                            .font(.title)
                            .foregroundStyle(OwlsColor.primary)

                        Text("\(c.name)")
                            .font(OwlsTypography.headline)
                            .foregroundStyle(OwlsColor.label)

                        Text("\(c.tileDesc)")
                            .font(OwlsTypography.caption)
                            .foregroundStyle(OwlsColor.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(OwlsSpacing.lg)
                    .background(OwlsColor.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: OwlsRadius.lg))
                }
                .buttonStyle(.plain)
            }
        }
        """
    }

    // MARK: - Router

    static func router(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        enum \(c.module)Router: OwlsRouter {

            case detail(\(c.name)Item)

            var id: String {
                switch self {
                case .detail(let item): "\(c.nameLower)-detail-\\(item.id)"
                }
            }

            @ViewBuilder
            func resolveViewForRoute() -> some View {
                switch self {
                case .detail(let item):
                    \(c.name)DetailView(item: item)
                }
            }
        }
        """
    }

    // MARK: - Detail View

    static func detailView(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        struct \(c.name)DetailView: View {

            let item: \(c.name)Item

            var body: some View {
                List {
                    Section {
                        VStack(spacing: OwlsSpacing.sm) {
                            Image(systemName: item.iconName)
                                .font(.largeTitle)
                                .foregroundStyle(OwlsColor.primary)

                            Text(item.title)
                                .font(OwlsTypography.title)

                            Text(item.subtitle)
                                .font(OwlsTypography.callout)
                                .foregroundStyle(OwlsColor.secondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OwlsSpacing.lg)
                    }

                    Section("Details") {
                        LabeledContent("ID", value: item.id)
                        LabeledContent("Created", value: item.createdAt, format: .dateTime)
                    }
                }
                .navigationTitle(item.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        """
    }

    // MARK: - Tile Builder

    static func tileBuilder(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore

        struct \(c.module)TileBuilder: MicroUITileBuilder {
            func buildTile() -> AnyView {
                AnyView(\(c.name)TileView())
            }
        }
        """
    }

    // MARK: - Screen Builder

    static func screenBuilder(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore
        import Factory

        struct \(c.module)ScreenBuilder: MicroUIScreenBuilder {
            func buildScreen() -> AnyView {
                let dataSource = Mock\(c.name)DataSource()
                let dispatcher = \(c.name)ServiceDispatcher(dataSource: dataSource)
                let repository = Default\(c.name)Repository(dispatcher: dispatcher)
                let viewModel = \(c.module)ViewModel(repository: repository)
                return AnyView(\(c.module)View(viewModel: viewModel))
            }
        }
        """
    }

    // MARK: - Tests

    static func tests(_ c: Context) -> String {
        """
        import Testing
        @testable import \(c.module)

        @Suite("\(c.module) ViewModel Tests")
        struct \(c.module)ViewModelTests {

            struct Stub\(c.name)Repository: \(c.name)Repository {
                var mockItems: [\(c.name)Item] = \(c.name)Item.mock
                var shouldFail = false

                func loadAll() async throws -> [\(c.name)Item] {
                    if shouldFail { throw TestError.mockFailure }
                    return mockItems
                }

                func loadDetail(id: String) async throws -> \(c.name)Item {
                    guard let item = mockItems.first(where: { $0.id == id }) else {
                        throw TestError.mockFailure
                    }
                    return item
                }

                func create(name: String) async throws -> \(c.name)Item {
                    \(c.name)Item(id: UUID().uuidString, title: name, subtitle: "Test", iconName: "star", createdAt: Date())
                }

                func delete(id: String) async throws {
                    if shouldFail { throw TestError.mockFailure }
                }
            }

            enum TestError: Error { case mockFailure }

            @Test("Load items successfully")
            func loadItems() async {
                let vm = \(c.module)ViewModel(repository: Stub\(c.name)Repository())
                await vm.load()
                #expect(vm.items.count == 3)
                #expect(vm.isLoading == false)
                #expect(vm.errorMessage == nil)
            }

            @Test("Load items failure shows error")
            func loadItemsFailure() async {
                let vm = \(c.module)ViewModel(repository: Stub\(c.name)Repository(shouldFail: true))
                await vm.load()
                #expect(vm.items.isEmpty)
                #expect(vm.errorMessage != nil)
            }

            @Test("Delete item removes from list")
            func deleteItem() async {
                let vm = \(c.module)ViewModel(repository: Stub\(c.name)Repository())
                await vm.load()
                let firstId = vm.items.first?.id ?? ""
                let countBefore = vm.items.count
                await vm.deleteItem(id: firstId)
                #expect(vm.items.count == countBefore - 1)
            }
        }
        """
    }

    // MARK: - Deep Link Handler

    static func deepLinkHandler(_ c: Context) -> String {
        """
        import Foundation
        import MicroUICore
        import Factory

        // MARK: - Deep Link Handler
        //
        // Handles URLs like: owlsapp://\(c.nameLower)/detail/123
        //
        // Registered in Config.swift via:
        //   OwlsDeepLinkRouter.shared.register(\(c.module)DeepLinkHandler())

        struct \(c.module)DeepLinkHandler: OwlsDeepLinkHandler {

            var supportedModules: [String] { ["\(c.nameLower)"] }

            func handle(_ deepLink: OwlsDeepLink) -> Bool {
                let coordinator = Container.shared.\(c.nameLower)NavigationCoordinator()

                // Parse the path: "\(c.nameLower)/detail/123"
                let components = deepLink.path.split(separator: "/")

                if components.first == "detail", let id = components.dropFirst().first {
                    // Pass data to coordinator and present
                    coordinator.present(style: .fullScreen, data: ["itemId": String(id)])
                    return true
                }

                // Default: just open the module
                coordinator.present(style: .fullScreen)
                return true
            }
        }
        """
    }

    // MARK: - Mock Provider

    static func mockProvider(_ c: Context) -> String {
        """
        import Foundation
        import MicroUICore

        // MARK: - Mock Provider
        //
        // Lists all mock JSON responses available for this module.
        // Appears in the Debug Drawer (DEBUG builds only).
        //
        // To add a new mock:
        //   1. Add a JSON file in Mocks/JSON/
        //   2. Append an OwlsMockItem below with matching endpoint + filename

        public struct \(c.module)MockProvider: OwlsMockProvider {

            public var moduleName: String { "\(c.module)" }

            public init() {}

            public func mockItems() -> [OwlsMockItem] {
                [
                    OwlsMockItem(
                        id: "\(c.nameLower).list.success",
                        name: "\(c.name) — Success (3 items)",
                        module: moduleName,
                        endpoint: "/v1/\(c.nameLower)",
                        method: .get,
                        jsonFilename: "\(c.nameLower)Success.json",
                        bundle: .module,
                        statusCode: 200,
                        category: .success
                    ),
                    OwlsMockItem(
                        id: "\(c.nameLower).list.empty",
                        name: "\(c.name) — Empty",
                        module: moduleName,
                        endpoint: "/v1/\(c.nameLower)",
                        method: .get,
                        jsonFilename: "\(c.nameLower)Empty.json",
                        bundle: .module,
                        statusCode: 200,
                        category: .empty
                    ),
                    OwlsMockItem(
                        id: "\(c.nameLower).list.failure",
                        name: "\(c.name) — 500 Server Error",
                        module: moduleName,
                        endpoint: "/v1/\(c.nameLower)",
                        method: .get,
                        jsonFilename: "\(c.nameLower)Failure.json",
                        bundle: .module,
                        statusCode: 500,
                        category: .failure
                    ),
                ]
            }
        }
        """
    }

    // MARK: - Mock JSON — Success

    static func mockJSONSuccess(_ c: Context) -> String {
        """
        [
            {
                "id": "mock-1",
                "title": "Sample \(c.name) 1",
                "subtitle": "Mocked from \(c.nameLower)Success.json",
                "iconName": "star.fill",
                "createdAt": "2026-04-24T12:00:00Z"
            },
            {
                "id": "mock-2",
                "title": "Sample \(c.name) 2",
                "subtitle": "Another mock item",
                "iconName": "heart.fill",
                "createdAt": "2026-04-24T12:00:00Z"
            },
            {
                "id": "mock-3",
                "title": "Sample \(c.name) 3",
                "subtitle": "Third mock item",
                "iconName": "bolt.fill",
                "createdAt": "2026-04-24T12:00:00Z"
            }
        ]
        """
    }

    // MARK: - Mock JSON — Empty

    static func mockJSONEmpty(_ c: Context) -> String {
        """
        []
        """
    }

    // MARK: - Mock JSON — Failure

    static func mockJSONFailure(_ c: Context) -> String {
        """
        {
            "error": "SERVER_ERROR",
            "message": "Failed to load \(c.nameLower). Please try again later."
        }
        """
    }
}
