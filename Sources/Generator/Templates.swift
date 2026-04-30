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
        import SwiftUI
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

            /// Factory for Example apps and host apps that want to render
            /// this module's screen directly without going through the Container.
            @MainActor
            public static func makeScreen() -> AnyView {
                \(c.module)ScreenBuilder().buildScreen()
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
        // Endpoint + method come from \(c.name)API — single source of truth.
        // Appears in the Debug Drawer (DEBUG builds only).
        //
        // To add a new mock:
        //   1. Add a JSON file in Mocks/JSON/
        //   2. Append an OwlsMockItem below referencing the route case

        public struct \(c.module)MockProvider: OwlsMockProvider {

            public var moduleName: String { "\(c.module)" }

            public init() {}

            public func mockItems() -> [OwlsMockItem] {
                // Reference the API route — endpoint/method come from \(c.name)API
                let listRoute = \(c.name)API.list

                return [
                    OwlsMockItem(
                        id: "\(c.nameLower).list.success",
                        name: "\(c.name) — Success (3 items)",
                        module: moduleName,
                        route: listRoute,
                        jsonFilename: "\(c.nameLower)Success.json",
                        bundle: .module,
                        statusCode: 200,
                        category: .success
                    ),
                    OwlsMockItem(
                        id: "\(c.nameLower).list.empty",
                        name: "\(c.name) — Empty",
                        module: moduleName,
                        route: listRoute,
                        jsonFilename: "\(c.nameLower)Empty.json",
                        bundle: .module,
                        statusCode: 200,
                        category: .empty
                    ),
                    OwlsMockItem(
                        id: "\(c.nameLower).list.failure",
                        name: "\(c.name) — 500 Server Error",
                        module: moduleName,
                        route: listRoute,
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

    // MARK: - Example App: SwiftUI entry point

    static func exampleApp(_ c: Context) -> String {
        """
        import SwiftUI
        import MicroUICore
        import \(c.module)

        @main
        struct \(c.name)ExampleApp: App {

            init() {
                ExampleBootstrap.run()
                OwlsImageCache.configure()
            }

            var body: some Scene {
                WindowGroup {
                    \(c.module)Config.makeScreen()
                        .owlsErrorAlert()
                        #if DEBUG
                        .overlay(alignment: .bottomTrailing) { OwlsDebugButton() }
                        #endif
                }
            }
        }
        """
    }

    // MARK: - Example App: Bootstrap with stubs

    static func exampleBootstrap(_ c: Context) -> String {
        """
        import MicroUICore
        import \(c.module)
        import Factory

        // To use REAL modules instead of stubs, add their packages to this xcodeproj
        // then uncomment the imports + registrations below.
        //
        // import FeatureHomeMicroUI
        // import FeatureProfileMicroUI
        // import AuthMicroUI

        enum ExampleBootstrap {

            static func run() {
                registerFocusedModule()
                registerCrossModuleStubs()
                registerCoreServices()
                enableDefaultMocks()
            }

            // MARK: - Register the focused module

            private static func registerFocusedModule() {
                \(c.module)Config().registerMicroUI()
            }

            // MARK: - Stub cross-module DI slots

            private static func registerCrossModuleStubs() {
                // Auth token — so OwlsBaseService works
                Container.shared.authTokenProvider.register {
                    OwlsStubAuthTokenProvider()
                }

                // Stubs for tile builders this module may embed.
                // Comment out + replace with real config to test integration.
                Container.shared.homeTileBuilder.register {
                    OwlsStubTileBuilder(label: "Home Tile")
                }
                Container.shared.profileTileBuilder.register {
                    OwlsStubTileBuilder(label: "Profile Tile")
                }

                // Real-module integration example:
                // FeatureHomeMicroUIConfig().registerMicroUI()
            }

            // MARK: - Core services

            private static func registerCoreServices() {
                Container.shared.analyticsProviders.register { [] }
            }

            // MARK: - Pre-enable success mocks

            private static func enableDefaultMocks() {
                #if DEBUG
                OwlsMockRegistry.shared.setEnabled("\(c.nameLower).list.success", enabled: true)
                #endif
            }
        }
        """
    }

    // MARK: - Example App: Asset catalog files

    static func exampleAssetsContents() -> String {
        """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
    }

    static func exampleAccentColor() -> String {
        """
        {
          "colors" : [
            {
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
    }

    static func exampleAppIcon() -> String {
        """
        {
          "images" : [
            {
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
    }

    // MARK: - Example App: Xcode project file

    static func examplePbxproj(_ c: Context) -> String {
        let appName = "\(c.name)ExampleApp"
        let module = c.module
        let bundleSuffix = "\(c.nameLower)exampleapp"

        return """
        // !$*UTF8*$!
        {
        \tarchiveVersion = 1;
        \tclasses = {
        \t};
        \tobjectVersion = 77;
        \tobjects = {

        /* Begin PBXBuildFile section */
        \t\tA1B2C3D4E5F60000000000A1 /* MicroUICore in Frameworks */ = {isa = PBXBuildFile; productRef = A1B2C3D4E5F60000000000A2 /* MicroUICore */; };
        \t\tA1B2C3D4E5F60000000000A3 /* \(module) in Frameworks */ = {isa = PBXBuildFile; productRef = A1B2C3D4E5F60000000000A4 /* \(module) */; };
        /* End PBXBuildFile section */

        /* Begin PBXFileReference section */
        \t\tA1B2C3D4E5F60000000000B0 /* \(appName).app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \(appName).app; sourceTree = BUILT_PRODUCTS_DIR; };
        /* End PBXFileReference section */

        /* Begin PBXFileSystemSynchronizedRootGroup section */
        \t\tA1B2C3D4E5F60000000000C0 /* \(appName) */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = \(appName);
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXFileSystemSynchronizedRootGroup section */

        /* Begin PBXFrameworksBuildPhase section */
        \t\tA1B2C3D4E5F60000000000D0 /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t\tA1B2C3D4E5F60000000000A1 /* MicroUICore in Frameworks */,
        \t\t\t\tA1B2C3D4E5F60000000000A3 /* \(module) in Frameworks */,
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXFrameworksBuildPhase section */

        /* Begin PBXGroup section */
        \t\tA1B2C3D4E5F60000000000E0 = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA1B2C3D4E5F60000000000C0 /* \(appName) */,
        \t\t\t\tA1B2C3D4E5F60000000000F0 /* Products */,
        \t\t\t);
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA1B2C3D4E5F60000000000F0 /* Products */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA1B2C3D4E5F60000000000B0 /* \(appName).app */,
        \t\t\t);
        \t\t\tname = Products;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXGroup section */

        /* Begin PBXNativeTarget section */
        \t\tA1B2C3D4E5F600000000010A /* \(appName) */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = A1B2C3D4E5F600000000020A /* Build configuration list for PBXNativeTarget "\(appName)" */;
        \t\t\tbuildPhases = (
        \t\t\t\tA1B2C3D4E5F600000000030A /* Sources */,
        \t\t\t\tA1B2C3D4E5F60000000000D0 /* Frameworks */,
        \t\t\t\tA1B2C3D4E5F600000000040A /* Resources */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t);
        \t\t\tfileSystemSynchronizedGroups = (
        \t\t\t\tA1B2C3D4E5F60000000000C0 /* \(appName) */,
        \t\t\t);
        \t\t\tname = \(appName);
        \t\t\tpackageProductDependencies = (
        \t\t\t\tA1B2C3D4E5F60000000000A2 /* MicroUICore */,
        \t\t\t\tA1B2C3D4E5F60000000000A4 /* \(module) */,
        \t\t\t);
        \t\t\tproductName = \(appName);
        \t\t\tproductReference = A1B2C3D4E5F60000000000B0 /* \(appName).app */;
        \t\t\tproductType = "com.apple.product-type.application";
        \t\t};
        /* End PBXNativeTarget section */

        /* Begin PBXProject section */
        \t\tA1B2C3D4E5F600000000050A /* Project object */ = {
        \t\t\tisa = PBXProject;
        \t\t\tattributes = {
        \t\t\t\tBuildIndependentTargetsInParallel = 1;
        \t\t\t\tLastSwiftUpdateCheck = 2630;
        \t\t\t\tLastUpgradeCheck = 2630;
        \t\t\t\tTargetAttributes = {
        \t\t\t\t\tA1B2C3D4E5F600000000010A = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 26.3;
        \t\t\t\t\t};
        \t\t\t\t};
        \t\t\t};
        \t\t\tbuildConfigurationList = A1B2C3D4E5F600000000060A /* Build configuration list for PBXProject "\(appName)" */;
        \t\t\tdevelopmentRegion = en;
        \t\t\thasScannedForEncodings = 0;
        \t\t\tknownRegions = (
        \t\t\t\ten,
        \t\t\t\tBase,
        \t\t\t);
        \t\t\tmainGroup = A1B2C3D4E5F60000000000E0;
        \t\t\tminimizedProjectReferenceProxies = 1;
        \t\t\tpackageReferences = (
        \t\t\t\tA1B2C3D4E5F600000000070A /* XCLocalSwiftPackageReference "../../MicroUICore" */,
        \t\t\t\tA1B2C3D4E5F600000000080A /* XCLocalSwiftPackageReference "../" */,
        \t\t\t);
        \t\t\tpreferredProjectObjectVersion = 77;
        \t\t\tproductRefGroup = A1B2C3D4E5F60000000000F0 /* Products */;
        \t\t\tprojectDirPath = "";
        \t\t\tprojectRoot = "";
        \t\t\ttargets = (
        \t\t\t\tA1B2C3D4E5F600000000010A /* \(appName) */,
        \t\t\t);
        \t\t};
        /* End PBXProject section */

        /* Begin PBXResourcesBuildPhase section */
        \t\tA1B2C3D4E5F600000000040A /* Resources */ = {
        \t\t\tisa = PBXResourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXResourcesBuildPhase section */

        /* Begin PBXSourcesBuildPhase section */
        \t\tA1B2C3D4E5F600000000030A /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXSourcesBuildPhase section */

        /* Begin XCBuildConfiguration section */
        \t\tA1B2C3D4E5F600000000090A /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_TESTABILITY = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
        \t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
        \t\t\t\t\t"DEBUG=1",
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t);
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tONLY_ACTIVE_ARCH = YES;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
        \t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\tA1B2C3D4E5F60000000000A0 /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ANALYZER_NONNULL = YES;
        \t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
        \t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
        \t\t\t\tCOPY_PHASE_STRIP = NO;
        \t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
        \t\t\t\tENABLE_NS_ASSERTIONS = NO;
        \t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
        \t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
        \t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
        \t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
        \t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
        \t\t\t\tMTL_FAST_MATH = YES;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\tA1B2C3D4E5F60000000000B1 /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
        \t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/Frameworks",
        \t\t\t\t);
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = aap.loudowls.\(bundleSuffix);
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\tA1B2C3D4E5F60000000000C1 /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tCURRENT_PROJECT_VERSION = 1;
        \t\t\t\tENABLE_PREVIEWS = YES;
        \t\t\t\tGENERATE_INFOPLIST_FILE = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
        \t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
        \t\t\t\t\t"$(inherited)",
        \t\t\t\t\t"@executable_path/Frameworks",
        \t\t\t\t);
        \t\t\t\tMARKETING_VERSION = 1.0;
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = aap.loudowls.\(bundleSuffix);
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        /* End XCBuildConfiguration section */

        /* Begin XCConfigurationList section */
        \t\tA1B2C3D4E5F600000000060A /* Build configuration list for PBXProject "\(appName)" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\tA1B2C3D4E5F600000000090A /* Debug */,
        \t\t\t\tA1B2C3D4E5F60000000000A0 /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\tA1B2C3D4E5F600000000020A /* Build configuration list for PBXNativeTarget "\(appName)" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\tA1B2C3D4E5F60000000000B1 /* Debug */,
        \t\t\t\tA1B2C3D4E5F60000000000C1 /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        /* End XCConfigurationList section */

        /* Begin XCLocalSwiftPackageReference section */
        \t\tA1B2C3D4E5F600000000070A /* XCLocalSwiftPackageReference "../../MicroUICore" */ = {
        \t\t\tisa = XCLocalSwiftPackageReference;
        \t\t\trelativePath = ../../MicroUICore;
        \t\t};
        \t\tA1B2C3D4E5F600000000080A /* XCLocalSwiftPackageReference "../" */ = {
        \t\t\tisa = XCLocalSwiftPackageReference;
        \t\t\trelativePath = ../;
        \t\t};
        /* End XCLocalSwiftPackageReference section */

        /* Begin XCSwiftPackageProductDependency section */
        \t\tA1B2C3D4E5F60000000000A2 /* MicroUICore */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tproductName = MicroUICore;
        \t\t};
        \t\tA1B2C3D4E5F60000000000A4 /* \(module) */ = {
        \t\t\tisa = XCSwiftPackageProductDependency;
        \t\t\tproductName = \(module);
        \t\t};
        /* End XCSwiftPackageProductDependency section */
        \t};
        \trootObject = A1B2C3D4E5F600000000050A /* Project object */;
        }

        """
    }
}
