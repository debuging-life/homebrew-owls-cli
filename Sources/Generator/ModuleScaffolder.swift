import Foundation

struct ModuleScaffolder {

    let projectRoot: String
    let context: Templates.Context

    private var pkgDir: String { "\(projectRoot)/Packages/\(context.module)" }
    private var srcDir: String { "\(pkgDir)/Sources/\(context.module)" }
    private var testDir: String { "\(pkgDir)/Tests/\(context.module)Tests" }

    // MARK: - Scaffold

    func scaffold() throws {
        try createDirectories()
        try writeFiles()
    }

    // MARK: - Directories

    private func createDirectories() throws {
        let fm = FileManager.default
        let dirs = [
            "\(srcDir)/Builder",
            "\(srcDir)/Data",
            "\(srcDir)/Domain/Models",
            "\(srcDir)/Localization",
            "\(srcDir)/ViewModels",
            "\(srcDir)/UI/Views",
            "\(srcDir)/UI/Screens",
            testDir,
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
            ("\(srcDir)/Builder/\(c.module)DeepLinkHandler.swift", Templates.deepLinkHandler(c)),
            ("\(testDir)/\(c.module)ViewModelTests.swift", Templates.tests(c)),
        ]

        for (path, content) in files {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
