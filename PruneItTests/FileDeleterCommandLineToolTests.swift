import Foundation
import Testing
@testable import PruneIt

/// The command-line tool gate is wired into the delete engine (#225): an
/// install's folder, shims and job plist go to the Trash, and a path the scan
/// did not pair is skipped for safety in the same call.
@Suite("FileDeleter honours the command-line tool gate")
struct FileDeleterCommandLineToolTests {
    @MainActor
    @Test func pairedInstallIsTrashedAndAStrayIsSkipped() async throws {
        let fm = FileManager.default
        let home = fm.temporaryDirectory
            .appendingPathComponent("pruneittest-\(UUID().uuidString)", isDirectory: true).standardizedFileURL
        defer { try? fm.removeItem(at: home) }
        let bin = home.appendingPathComponent(".local/bin", isDirectory: true)
        let folder = home.appendingPathComponent(".pruneittest-cli", isDirectory: true)
        let stray = home.appendingPathComponent(".pruneittest-other", isDirectory: true)
        try fm.createDirectory(at: bin, withIntermediateDirectories: true)
        try fm.createDirectory(at: folder.appendingPathComponent("bin"), withIntermediateDirectories: true)
        try fm.createDirectory(at: stray, withIntermediateDirectories: true)
        let program = folder.appendingPathComponent("bin/pruneittest-cli")
        try Data("#!/bin/sh\necho\n".utf8).write(to: program)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: program.path)
        // Named after its folder, as the pairing rule requires.
        let shim = bin.appendingPathComponent("pruneittest-cli")
        try fm.createSymbolicLink(atPath: shim.path, withDestinationPath: program.path)
        let inside = program

        let trash = FakeTrash()
        let report = try await FileDeleter(home: home, trash: trash.trash)
            .deleteUserSelectedFiles(at: [folder, shim, stray, inside])

        #expect(trash.trashedPaths == [folder.standardizedFileURL.path, shim.standardizedFileURL.path])
        #expect(Set(report.skippedItems.map { URL(fileURLWithPath: $0.path).standardizedFileURL.path })
            == [stray.standardizedFileURL.path, inside.standardizedFileURL.path])
    }
}
