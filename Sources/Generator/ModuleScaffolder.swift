import Foundation

struct ModuleScaffolder {

    let projectRoot: String
    let context: Templates.Context
    let includeSandbox: Bool

    private var pkgDir: String { "\(projectRoot)/Packages/\(context.module)" }
    private var srcDir: String { "\(pkgDir)/Sources/\(context.module)" }
    private var testDir: String { "\(pkgDir)/Tests/\(context.module)Tests" }
    private var exampleDir: String { "\(pkgDir)/Example" }
    private var exampleAppName: String { "\(context.name)ExampleApp" }

    init(projectRoot: String, context: Templates.Context, includeSandbox: Bool = true) {
        self.projectRoot = projectRoot
        self.context = context
        self.includeSandbox = includeSandbox
    }

    // MARK: - Scaffold

    func scaffold() throws {
        try createDirectories()
        try writeFiles()
        if includeSandbox {
            try createSandboxDirectories()
            try writeSandboxFiles()
        }
    }

    // MARK: - Directories

    private func createDirectories() throws {
        let fm = FileManager.default
        let dirs = [
            "\(srcDir)/Builder",
            "\(srcDir)/Data",
            "\(srcDir)/Domain/Models",
            "\(srcDir)/Localization",
            "\(srcDir)/Mocks/JSON",
            "\(srcDir)/ViewModels",
            "\(srcDir)/UI/Views",
            "\(srcDir)/UI/Screens",
            testDir,
        ]
        for dir in dirs {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }

    private func createSandboxDirectories() throws {
        let fm = FileManager.default
        let dirs = [
            "\(exampleDir)/\(exampleAppName)/Assets.xcassets/AccentColor.colorset",
            "\(exampleDir)/\(exampleAppName)/Assets.xcassets/AppIcon.appiconset",
            "\(exampleDir)/\(exampleAppName).xcodeproj",
        ]
        for dir in dirs {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Files

    private func writeFiles() throws {
        let c = context
        let files: [(String, String)] = [
            ("\(pkgDir)/Package.swift", Templates.packageSwift(c)),
            ("\(srcDir)/Builder/\(c.module)Config.swift", Templates.config(c)),
            ("\(srcDir)/Builder/\(c.module)Router.swift", Templates.router(c)),
            ("\(srcDir)/Builder/\(c.module)TileBuilder.swift", Templates.tileBuilder(c)),
            ("\(srcDir)/Builder/\(c.module)ScreenBuilder.swift", Templates.screenBuilder(c)),
            ("\(srcDir)/Builder/\(c.module)DeepLinkHandler.swift", Templates.deepLinkHandler(c)),
            ("\(srcDir)/Data/\(c.name)API.swift", Templates.apiRoutes(c)),
            ("\(srcDir)/Data/\(c.module)DataSource.swift", Templates.dataSource(c)),
            ("\(srcDir)/Data/\(c.module)ServiceDispatcher.swift", Templates.serviceDispatcher(c)),
            ("\(srcDir)/Domain/Models/\(c.name)Item.swift", Templates.domainModel(c)),
            ("\(srcDir)/Domain/\(c.module)Repository.swift", Templates.repository(c)),
            ("\(srcDir)/Localization/\(c.name)LocalizedString.swift", Templates.localizedStrings(c)),
            ("\(srcDir)/ViewModels/\(c.module)ViewModel.swift", Templates.viewModel(c)),
            ("\(srcDir)/UI/Screens/\(c.module)View.swift", Templates.screenView(c)),
            ("\(srcDir)/UI/Screens/\(c.name)DetailView.swift", Templates.detailView(c)),
            ("\(srcDir)/UI/Screens/\(c.name)CreateSheet.swift", Templates.createSheet(c)),
            ("\(srcDir)/UI/Views/\(c.name)TileView.swift", Templates.tileView(c)),
            ("\(srcDir)/Mocks/\(c.module)MockProvider.swift", Templates.mockProvider(c)),
            ("\(srcDir)/Mocks/JSON/\(c.nameLower)Success.json", Templates.mockJSONSuccess(c)),
            ("\(srcDir)/Mocks/JSON/\(c.nameLower)Empty.json", Templates.mockJSONEmpty(c)),
            ("\(srcDir)/Mocks/JSON/\(c.nameLower)Failure.json", Templates.mockJSONFailure(c)),
            ("\(testDir)/\(c.module)ViewModelTests.swift", Templates.tests(c)),
        ]

        for (path, content) in files {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    private func writeSandboxFiles() throws {
        let c = context
        let app = exampleAppName
        let files: [(String, String)] = [
            ("\(exampleDir)/\(app)/\(app).swift", Templates.exampleApp(c)),
            ("\(exampleDir)/\(app)/ExampleBootstrap.swift", Templates.exampleBootstrap(c)),
            ("\(exampleDir)/\(app)/Assets.xcassets/Contents.json", Templates.exampleAssetsContents()),
            ("\(exampleDir)/\(app)/Assets.xcassets/AccentColor.colorset/Contents.json", Templates.exampleAccentColor()),
            ("\(exampleDir)/\(app)/Assets.xcassets/AppIcon.appiconset/Contents.json", Templates.exampleAppIcon()),
            ("\(exampleDir)/\(app).xcodeproj/project.pbxproj", Templates.examplePbxproj(c)),
        ]

        for (path, content) in files {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
