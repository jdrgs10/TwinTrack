import PhotosUI
import SwiftUI
import UIKit

enum ProfileStorage {
    static let studentNameKey = "TwinTrack.profile.studentName.v1"
    static let gradeLevelKey = "TwinTrack.profile.gradeLevel.v1"

    static func defaults() -> UserDefaults {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--synthetic-profile-ui-tests"),
           arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]),
           let defaults = UserDefaults(suiteName: "TwinTrack.ProfileUITests.\(id.uuidString)") {
            return defaults
        }
#endif
        return .standard
    }

    static func normalized(_ value: String, maximumLength: Int = 60) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maximumLength else { return nil }
        return trimmed
    }

    static func profileImageURL(fileManager: FileManager = .default) -> URL {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--synthetic-profile-ui-tests"),
           arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]) {
            return fileManager.temporaryDirectory
                .appendingPathComponent("TwinTrack.ProfileUITests.\(id.uuidString)", isDirectory: true)
                .appendingPathComponent("profile-image.jpg")
        }
#endif
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TwinTrackProfile", isDirectory: true)
            .appendingPathComponent("profile-image.jpg")
    }

    static func profileSourceImageURL(fileManager: FileManager = .default) -> URL {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--synthetic-profile-ui-tests"),
           arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]) {
            return fileManager.temporaryDirectory
                .appendingPathComponent("TwinTrack.ProfileUITests.\(id.uuidString)", isDirectory: true)
                .appendingPathComponent("profile-source.jpg")
        }
#endif
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TwinTrackProfile", isDirectory: true)
            .appendingPathComponent("profile-source.jpg")
    }
}

@MainActor
enum ProfileImageStorage {
    enum StorageError: Error { case invalidImage }

    static func load(from fileURL: URL) -> Data? {
        let began = ProcessInfo.processInfo.systemUptime
        defer { AssistantPerformance.mark(.profileImageLoad, duration: ProcessInfo.processInfo.systemUptime - began) }
        guard let data = try? Data(contentsOf: fileURL), UIImage(data: data) != nil else { return nil }
        return data
    }

    static func normalizedJPEG(from sourceData: Data) -> Data? {
        ProfilePhotoCropper.sanitizedSourceJPEG(from: sourceData)
    }

    static func save(_ data: Data?, to fileURL: URL, fileManager: FileManager = .default) throws {
        guard let data else {
            if fileManager.fileExists(atPath: fileURL.path) { try fileManager.removeItem(at: fileURL) }
            return
        }
        guard UIImage(data: data) != nil else { throw StorageError.invalidImage }
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        var directoryResources = URLResourceValues()
        directoryResources.isExcludedFromBackup = true
        var mutableDirectory = directory
        try mutableDirectory.setResourceValues(directoryResources)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        var mutableFile = fileURL
        try mutableFile.setResourceValues(directoryResources)
    }
}

struct ProfileView: View {
    @Environment(\.appearanceSelection) private var appearanceSelection
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage private var studentName: String
    @AppStorage private var gradeLevel: String
    @State private var profileImageData: Data?
    @State private var profileSourceImageData: Data?
    @State private var profileImageError: String?
    @State private var isShowingManualInputs = false
    @State private var isShowingEditProfile = false
    private let profileImageURL: URL
    private let profileSourceImageURL: URL

    init(defaults: UserDefaults = ProfileStorage.defaults()) {
        let imageURL = ProfileStorage.profileImageURL()
        let sourceImageURL = ProfileStorage.profileSourceImageURL()
        let avatar = ProfileImageStorage.load(from: imageURL)
        _studentName = AppStorage(wrappedValue: "", ProfileStorage.studentNameKey, store: defaults)
        _gradeLevel = AppStorage(wrappedValue: "", ProfileStorage.gradeLevelKey, store: defaults)
        _profileImageData = State(initialValue: avatar)
        // A legacy avatar predates editable-source storage. It remains a valid,
        // metadata-free fallback source until the user chooses another photo.
        _profileSourceImageData = State(initialValue: avatar.flatMap {
            ProfileImageStorage.load(from: sourceImageURL) ?? $0
        })
        profileImageURL = imageURL
        profileSourceImageURL = sourceImageURL
    }

    private var palette: ProfilePalette { ProfilePalette(colorScheme) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    PageHeader(
                        title: "Profile",
                        subtitle: "Your data. Your preferences. Your control.",
                        showsMark: false
                    )

                    profileCard

                    sectionTitle("DATA SOURCES")
                    groupedRows {
                        NavigationLink {
                            HealthKitView()
                        } label: {
                            dataSourceRow(
                                title: "Apple Health",
                                detail: "Sleep, steps, exercise and resting heart rate",
                                systemImage: "heart.fill",
                                accent: palette.positive,
                                status: healthStatus
                            )
                        }
                        Divider().padding(.leading, 57)
                        Button {
                            isShowingManualInputs = true
                        } label: {
                            dataSourceRow(
                                title: "Manual Inputs",
                                detail: manualInputSummary,
                                systemImage: "pencil",
                                accent: palette.secondaryText,
                                status: "Entered in TwinTrack"
                            )
                        }
                        .accessibilityIdentifier("manualInputsButton")
                    }

                    sectionTitle("PREDICTION & AI")
                    VStack(spacing: 9) {
                        featureLink(
                            destination: .modelInformation,
                            eyebrow: "PREDICTION ENGINE",
                            title: "Ridge Regression",
                            detail: "Deterministic · On-device",
                            systemImage: "chart.line.uptrend.xyaxis",
                            accent: palette.accentText,
                            surface: palette.accentSurface,
                            border: palette.accentBorder
                        )
                        featureLink(
                            destination: .predictionMethodology,
                            eyebrow: "AI EXPLANATIONS",
                            title: "Apple Foundation Models",
                            detail: "Explains results · Never calculates scores",
                            systemImage: "sparkles",
                            accent: palette.aiText,
                            surface: palette.aiSurface,
                            border: palette.aiBorder
                        )
                    }
                    .padding(.horizontal, 16)

                    sectionTitle("PRIVACY & DATA")
                    groupedRows {
                        profileLink(
                            title: "Health Permissions",
                            detail: "Choose which Health types TwinTrack can read",
                            destination: AnyView(HealthKitView()),
                            identifier: "healthPermissionsButton"
                        )
                        Divider().padding(.leading, 15)
                        profileLink(
                            title: "Data & Privacy",
                            detail: PredictionHistoryDisplay.historySummary(state.predictionHistory.count),
                            destination: AnyView(DataPrivacyView()),
                            identifier: "dataPrivacyButton"
                        )
                        Divider().padding(.leading, 15)
                        profileLink(
                            title: "Prediction Methodology",
                            detail: "How the frozen Ridge model works",
                            destination: AnyView(ProfileDetailView(destination: .predictionMethodology)),
                            identifier: "predictionMethodologyButton"
                        )
                    }

                    onDeviceCard

                    sectionTitle("APPEARANCE")
                    groupedRows {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Appearance").font(.subheadline.weight(.medium))
                            Picker("Appearance", selection: appearanceSelection) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    Text(appearance.title).tag(appearance)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("appearancePicker")
                            Text("System follows your device. Light or Dark applies to TwinTrack only.")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryText)
                        }
                        .padding(15)
                    }

                    sectionTitle("ABOUT")
                    groupedRows {
                        aboutLink("About TwinTrack AI", destination: .about)
                        Divider().padding(.leading, 15)
                        aboutLink("Model Information", value: "Ridge · On-device", destination: .modelInformation)
                        Divider().padding(.leading, 15)
                        aboutLink("Privacy Policy", destination: .privacyPolicy)
                        Divider().padding(.leading, 15)
                        aboutLink("Terms of Use", destination: .termsOfUse)
                        Divider().padding(.leading, 15)
                        aboutLink("Prediction Disclaimer", destination: .predictionDisclaimer)
                        Divider().padding(.leading, 15)
                        HStack {
                            Text("App Version").font(.subheadline.weight(.medium))
                            Spacer()
                            Text(appVersion).font(.caption).foregroundStyle(palette.tertiaryText)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 14)
                    }

                    Text("TwinTrack AI · Graduation Project")
                        .font(.caption2)
                        .foregroundStyle(palette.tertiaryText)
                        .padding(.vertical, 22)
                }
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(palette.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileSheet(
                    initialName: studentName,
                    initialGradeLevel: gradeLevel,
                    initialImageData: profileImageData,
                    initialSourceImageData: profileSourceImageData
                ) { name, grade, imageData, sourceImageData in
                    studentName = name
                    gradeLevel = grade
                    do {
                        try ProfileImageStorage.save(sourceImageData, to: profileSourceImageURL)
                        try ProfileImageStorage.save(imageData, to: profileImageURL)
                        profileImageData = imageData
                        profileSourceImageData = sourceImageData
                    } catch {
                        profileImageError = "Your profile details were saved, but the selected photo could not be stored."
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert("Profile Photo Not Saved", isPresented: Binding(
                get: { profileImageError != nil },
                set: { if !$0 { profileImageError = nil } }
            )) {
                Button("OK", role: .cancel) { profileImageError = nil }
            } message: {
                Text(profileImageError ?? "")
            }
            .sheet(isPresented: $isShowingManualInputs) {
                ManualInputsSheet(
                    initialStudyMinutes: state.studyMinutes,
                    initialScreenTimeMinutes: state.screenTimeMinutes,
                    initialPreviousScore: state.previousScore,
                    initialContext: state.predictionContext
                )
                .environmentObject(state)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            ProfileAvatar(imageData: profileImageData, initials: initials, size: 52, palette: palette)
                .accessibilityLabel(profileImageData == nil ? "Default profile avatar" : "Profile photo")
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName).font(.headline).accessibilityIdentifier("profileDisplayName")
                Text(displayGrade).font(.caption).foregroundStyle(palette.secondaryText)
                    .accessibilityIdentifier("profileDisplayGrade")
            }
            Spacer(minLength: 8)
            Button("Edit Profile") { isShowingEditProfile = true }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(palette.border, in: Capsule())
                .accessibilityIdentifier("editProfileButton")
        }
        .padding(16)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(palette.border, lineWidth: 1) }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(palette.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 9)
    }

    private func groupedRows<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .buttonStyle(.plain)
            .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1) }
            .padding(.horizontal, 16)
    }

    private func dataSourceRow(
        title: String,
        detail: String,
        systemImage: String,
        accent: Color,
        status: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)
                .background(palette.border, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 7) {
                        Text(title).font(.subheadline.weight(.medium))
                        statusPill(status, color: accent)
                    }
                    Text(title).font(.subheadline.weight(.medium))
                }
                Text(detail).font(.caption).foregroundStyle(palette.secondaryText)
            }
            Spacer(minLength: 6)
            chevron
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: Capsule())
    }

    private func featureLink(
        destination: ProfileDetailDestination,
        eyebrow: String,
        title: String,
        detail: String,
        systemImage: String,
        accent: Color,
        surface: Color,
        border: Color
    ) -> some View {
        NavigationLink {
            ProfileDetailView(destination: destination)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(surface, in: RoundedRectangle(cornerRadius: 9))
                    .overlay { RoundedRectangle(cornerRadius: 9).stroke(border, lineWidth: 1) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(eyebrow).font(.caption2.weight(.semibold)).tracking(0.6).foregroundStyle(accent)
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.caption).foregroundStyle(palette.secondaryText)
                }
                Spacer()
                chevron
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1) }
    }

    private func profileLink(title: String, detail: String, destination: AnyView, identifier: String) -> some View {
        NavigationLink { destination } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.medium))
                    Text(detail).font(.caption).foregroundStyle(palette.secondaryText)
                }
                Spacer()
                chevron
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(identifier)
    }

    private var onDeviceCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("On-device-first", systemImage: "shield")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.accentText)
            Text("TwinTrack is designed to process prediction inputs locally. Health data and numerical prediction calculations are never delegated to the language model.")
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1) }
        .padding(.horizontal, 16)
        .padding(.top, 9)
    }

    private func aboutLink(_ title: String, value: String = "", destination: ProfileDetailDestination) -> some View {
        NavigationLink {
            ProfileDetailView(destination: destination)
        } label: {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.caption).foregroundStyle(palette.tertiaryText)
                }
                chevron
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("profileDetail.\(destination.rawValue)")
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(palette.tertiaryText)
            .accessibilityHidden(true)
    }

    private var displayName: String { ProfileStorage.normalized(studentName) ?? "Student" }
    private var displayGrade: String { ProfileStorage.normalized(gradeLevel) ?? "Grade level not set" }
    private var initials: String {
        let words = displayName.split(separator: " ")
        guard let first = words.first else { return "S" }
        let firstInitial = String(first.prefix(1)).uppercased()
        let lastInitial = words.count > 1 ? String(words[words.index(before: words.endIndex)].prefix(1)).uppercased() : ""
        return firstInitial + lastInitial
    }
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unavailable"
    }
    private var healthStatus: String {
        let values = [state.sleepHours, state.steps, state.exerciseMinutes, state.restingHeartRate]
        return values.contains(where: { $0 != nil }) ? "Recent data available" : "No accessible recent value"
    }
    private var manualInputSummary: String {
        let enteredCount = [state.studyMinutes != nil, state.screenTimeMinutes != nil, state.previousScore != nil]
            .filter { $0 }.count
        return enteredCount == 0 ? "Study time, screen time and previous score · Not entered" : "\(enteredCount) of 3 values entered"
    }
}

private struct EditProfileSheet: View {
    private struct CropSelection: Identifiable, Hashable {
        let id = UUID()
        let data: Data
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name: String
    @State private var gradeLevel: String
    @State private var imageData: Data?
    @State private var sourceImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cropSelection: CropSelection?
    @State private var photoError: String?
    @State private var isPreparingPhoto = false
    let onSave: (String, String, Data?, Data?) -> Void

    init(
        initialName: String,
        initialGradeLevel: String,
        initialImageData: Data?,
        initialSourceImageData: Data?,
        onSave: @escaping (String, String, Data?, Data?) -> Void
    ) {
        _name = State(initialValue: initialName)
        _gradeLevel = State(initialValue: initialGradeLevel)
        _imageData = State(initialValue: initialImageData)
        _sourceImageData = State(initialValue: initialSourceImageData)
        self.onSave = onSave
    }

    private var normalizedName: String? { ProfileStorage.normalized(name) }
    private var normalizedGrade: String? { ProfileStorage.normalized(gradeLevel, maximumLength: 30) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 15) {
                        ProfileAvatar(
                            imageData: imageData,
                            initials: draftInitials,
                            size: 64,
                            palette: ProfilePalette(colorScheme)
                        )
                        VStack(alignment: .leading, spacing: 7) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text(imageData == nil ? "Choose Photo" : "Change Photo")
                                    .frame(minHeight: 44)
                            }
                            .accessibilityIdentifier("profilePhotoPicker")
                            .disabled(isPreparingPhoto)
                            if imageData != nil {
                                Button("Edit Photo") {
                                    if let sourceImageData {
                                        cropSelection = CropSelection(data: sourceImageData)
                                    }
                                }
                                .frame(minHeight: 44)
                                .disabled(sourceImageData == nil || isPreparingPhoto)
                                .accessibilityIdentifier("editProfilePhotoButton")
                                Button("Remove Photo", role: .destructive) {
                                    imageData = nil
                                    sourceImageData = nil
                                }
                                    .frame(minHeight: 44)
                                    .disabled(isPreparingPhoto)
                                    .accessibilityIdentifier("removeProfilePhotoButton")
                            }
                            if isPreparingPhoto {
                                ProgressView()
                                    .accessibilityLabel("Preparing photo")
                                    .accessibilityIdentifier("profilePhotoPreparing")
                            }
                        }
                    }
                } footer: {
                    Text("Optional. Your profile photo is stored locally by TwinTrack and is not uploaded by the app.")
                }
                Section {
                    TextField("Student name", text: $name)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .accessibilityIdentifier("profileNameField")
                    TextField("Grade level", text: $gradeLevel)
                        .submitLabel(.done)
                        .accessibilityIdentifier("profileGradeField")
                } footer: {
                    Text("Profile details stay on this device and are not prediction inputs.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let normalizedName, let normalizedGrade else { return }
                        onSave(normalizedName, normalizedGrade, imageData, sourceImageData)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(normalizedName == nil || normalizedGrade == nil)
                    .accessibilityIdentifier("saveProfileButton")
                }
            }
            .task(id: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                isPreparingPhoto = true
                defer { isPreparingPhoto = false }
                do {
                    guard let originalData = try await item.loadTransferable(type: Data.self) else {
                        photoError = "That image could not be used. Choose another photo."
                        selectedPhoto = nil
                        return
                    }
                    try Task.checkCancellation()
                    let prepared = await Task.detached(priority: .userInitiated) {
                        ProfilePhotoCropper.sanitizedSourceJPEG(from: originalData)
                    }.value
                    try Task.checkCancellation()
                    guard let prepared else {
                        photoError = "That image could not be used. Choose another photo."
                        selectedPhoto = nil
                        return
                    }
                    selectedPhoto = nil
                    photoError = nil
                    cropSelection = CropSelection(data: prepared)
                } catch is CancellationError {
                    return
                } catch {
                    selectedPhoto = nil
                    photoError = "That image could not be loaded. Choose another photo."
                }
            }
            .navigationDestination(item: $cropSelection) { selection in
                if let editor = ProfilePhotoCropEditor(
                    sourceData: selection.data,
                    onSave: { croppedData in
                        sourceImageData = selection.data
                        imageData = croppedData
                    }
                ) {
                    editor
                } else {
                    Text("That image could not be used.")
                }
            }
            .alert("Photo Unavailable", isPresented: Binding(
                get: { photoError != nil },
                set: { if !$0 { photoError = nil } }
            )) {
                Button("OK", role: .cancel) { photoError = nil }
            } message: {
                Text(photoError ?? "")
            }
        }
    }

    private var draftInitials: String {
        let displayName = ProfileStorage.normalized(name) ?? "Student"
        let words = displayName.split(separator: " ")
        guard let first = words.first else { return "S" }
        let firstInitial = String(first.prefix(1)).uppercased()
        let lastInitial = words.count > 1 ? String(words.last!.prefix(1)).uppercased() : ""
        return firstInitial + lastInitial
    }
}

enum ProfileDetailDestination: String, Identifiable, Equatable {
    case predictionMethodology, modelInformation, about, privacyPolicy, termsOfUse, predictionDisclaimer
    var id: String { rawValue }

    var title: String {
        switch self {
        case .predictionMethodology: "Prediction Methodology"
        case .modelInformation: "Model Information"
        case .about: "About TwinTrack AI"
        case .privacyPolicy: "Privacy Policy"
        case .termsOfUse: "Terms of Use"
        case .predictionDisclaimer: "Prediction Disclaimer"
        }
    }

    var blocks: [(String?, String)] {
        switch self {
        case .predictionMethodology:
            return [
                (nil, "TwinTrack Ridge V2 · 2.0-final.1 estimates the next same-subject individual assessment score, 1–7 days ahead. Real-student predictive accuracy remains unverified."),
                ("Source periods", "Study means yesterday’s outside-class study for that subject. Screen time means yesterday’s recreational use, excluding study. The prior percentage score must be the latest comparable same-subject result, 1–90 days old."),
                ("Apple Health", "Recent sleep uses yesterday noon to the earlier of now or today noon. Steps and exercise use the previous completed day. Resting heart rate is the latest accessible sample within 72 hours."),
                ("Seven inputs", "Sleep, steps, exercise, resting heart rate, study time, screen time and previous score are all required for a numerical prediction."),
                ("Deterministic", "Identical inputs always return an identical score. There is no randomness between runs."),
                ("Predictive, not causal", "The model describes relationships it observed in training data. It does not prove that changing a habit will change your grade."),
                ("What Ridge Regression is", "Ridge Regression combines the seven model inputs using learned coefficients. Its regularization discourages overly large coefficients and helps reduce overfitting."),
                ("The language model never does the maths", "Apple Foundation Models interprets your request, calls the TwinTrack prediction tool and explains the returned number."),
            ]
        case .modelInformation:
            return [
                ("Model", "TwinTrack Ridge V2 · 2.0-final.1"),
                ("Training", "StandardScaler + Ridge, alpha 0.1. Evidence-informed synthetic data. Real-student predictive accuracy remains unverified."),
                ("Status", "Frozen"),
                ("Execution", "On-device"),
                ("Inputs", "7"),
                ("Numerical source", "Ridge model"),
                (nil, "The model ships with the app and is not retrained at runtime. All prediction and What-If numbers are calculated on-device using this fixed model."),
            ]
        case .about:
            return [
                ("Understand your habits. Build a better routine.", "TwinTrack AI helps students understand their sleep, physical activity and study habits by bringing relevant Apple Health information together with information they log."),
                ("More than a predicted score", "Assessment estimates and What-If scenarios help students explore the model as a supporting feature. Predictions are experimental: they do not measure student ability and do not prove that changing one habit causes grades to improve."),
                (nil, "Developed as a Grade 12 graduation project."),
            ]
        case .privacyPolicy:
            return [
                (nil, "TwinTrack AI handles only the information needed for its current app features."),
                ("HealthKit data", "With permission, TwinTrack reads summarized sleep, steps, exercise and resting-heart-rate values for the documented time windows. Raw Health samples are not saved in TwinTrack storage."),
                ("Stored app data", "Manual inputs, prediction history, saved chats, profile name and grade are stored locally. An optional processed avatar and resized editing source are stored in protected local app storage and excluded from system backup."),
                ("Foundation Models and tools", "For a personalized request, current summarized TwinTrack values and relevant conversation content may be provided to Apple's on-device Foundation Models framework. Numerical predictions remain separate and are calculated by the local Ridge model."),
                ("External services", "The current app has no TwinTrack account, server backend, cloud sync or analytics. System backups may include some locally stored app preferences and prediction history; saved chats and optional profile images are excluded from backup."),
                ("Your control", "You can review Health access in Settings, clear prediction history from Data & Privacy, delete saved chats from Chat Library, and remove your profile image from Edit Profile."),
            ]
        case .termsOfUse:
            return [
                (nil, "TwinTrack AI is a student project provided for educational use."),
                ("Intended use", "The app is for personal reflection on logged habits. It is not a medical, diagnostic or academic assessment tool."),
                ("No warranty", "The app is provided as-is. Availability, accuracy and continuity are not guaranteed."),
                ("Your responsibility", "Manual inputs are entered by you. Inaccurate inputs produce inaccurate predictions."),
            ]
        case .predictionDisclaimer:
            return [
                ("Educational predictions only", "TwinTrack AI provides educational predictions from a small frozen model. Results are not a forecast of your actual grade."),
                ("Predictive, not causal", "The model reflects statistical relationships in its training data. It does not show that changing a habit causes a change in performance."),
                ("Not a guaranteed outcome", "Predicted scores must not be treated as guaranteed academic outcomes, promises or advice about your studies."),
                ("Numbers come from the model", "All prediction and What-If numbers come from the on-device Ridge model. Apple Foundation Models only explains them."),
            ]
        }
    }
}

struct ProfileDetailView: View {
    let destination: ProfileDetailDestination
    @Environment(\.colorScheme) private var colorScheme
    private var palette: ProfilePalette { ProfilePalette(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 11) {
                ForEach(Array(destination.blocks.enumerated()), id: \.offset) { _, block in
                    VStack(alignment: .leading, spacing: 6) {
                        if let title = block.0 {
                            Text(title).font(.subheadline.weight(.semibold))
                        }
                        Text(block.1)
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(palette.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(palette.border) }
                }
                if destination == .predictionMethodology {
                    note("No accuracy statistics, training results or coefficients are shown in the app.")
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(palette.secondaryText)
    }
}

private struct ManualInputsSheet: View {
    @EnvironmentObject private var state: TwinTrackState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var draftStudyMinutes: Int?
    @State private var draftScreenTimeMinutes: Int?
    @State private var previousScoreText: String
    @State private var openPicker: TimeInput?
    @State private var subject: String
    @State private var assessmentName: String
    @State private var assessmentDate: Date
    @State private var previousDate: Date
    @State private var confirmed: Bool
    @State private var saveIssue: String?
    @State private var manualDay: Date
    @State private var sourceTimeZone: String

    private enum TimeInput { case study, screen }

    init(initialStudyMinutes: Int?, initialScreenTimeMinutes: Int?, initialPreviousScore: Double?, initialContext: V2PredictionContext? = nil) {
        _draftStudyMinutes = State(initialValue: initialStudyMinutes)
        _draftScreenTimeMinutes = State(initialValue: initialScreenTimeMinutes)
        _previousScoreText = State(initialValue: Self.scoreText(initialPreviousScore))
        _subject = State(initialValue: initialContext?.subject ?? "")
        _assessmentName = State(initialValue: initialContext?.assessmentName ?? "")
        // Today is ineligible for both dates; untouched date controls cannot grant eligibility.
        _assessmentDate = State(initialValue: initialContext?.assessmentDate ?? Date())
        _previousDate = State(initialValue: initialContext?.previousDate ?? Date())
        _confirmed = State(initialValue: false)
        let calendar = Calendar.current
        _manualDay = State(initialValue: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!)
        _sourceTimeZone = State(initialValue: calendar.timeZone.identifier)
    }

    private var border: Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color(red: 221/255, green: 227/255, blue: 236/255)
    }
    private var card: Color { colorScheme == .dark ? Color.white.opacity(0.028) : .white }
    private var isScoreValid: Bool { PreviousScoreInput.isValidDraft(previousScoreText) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 9) {
                    timeField(title: "Study Time", value: $draftStudyMinutes, input: .study)
                    Text("Yesterday’s outside-class study for this subject, including study on screens. Exclude classes, breaks and overlaps.").font(.caption).foregroundStyle(.secondary)
                    timeField(title: "Screen Time", value: $draftScreenTimeMinutes, input: .screen)
                    Text("Yesterday’s recreational screens. Exclude study; count overlapping devices once.").font(.caption).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Previous Score").font(.caption).foregroundStyle(.secondary)
                                TextField("Not entered", text: $previousScoreText)
                                    .keyboardType(.decimalPad)
                                    .font(.body.weight(.medium))
                                    .accessibilityIdentifier("previousScoreField")
                            }
                            Text("manual").font(.caption).foregroundStyle(.tertiary)
                        }
                        if !isScoreValid {
                            Text("Enter a number from 0 to 100.").font(.caption).foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(card, in: RoundedRectangle(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(isScoreValid ? border : .red) }
                    Text("Latest comparable same-subject result, as a percentage (for example, 40/50 = 80).").font(.caption).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Subject", text: $subject).accessibilityIdentifier("v2Subject")
                        TextField("Next quiz / test / exam", text: $assessmentName).accessibilityIdentifier("v2Assessment")
                        DatePicker("Next assessment · 1–7 days ahead", selection: $assessmentDate, displayedComponents: .date)
                            .accessibilityIdentifier("v2AssessmentDate")
                        DatePicker("Previous result · 1–90 days old", selection: $previousDate, displayedComponents: .date)
                            .accessibilityIdentifier("v2PreviousDate")
                        Toggle("I confirm the next individual assessment, latest comparable individual result, and study time are for this subject.", isOn: $confirmed)
                            .font(.caption).accessibilityIdentifier("v2ConfirmContext")
                        Text("Saving confirms the manual durations are for \(manualDay.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(14).background(card, in: RoundedRectangle(cornerRadius: 14))
                    if let saveIssue { Text(saveIssue).font(.caption).foregroundStyle(.red) }
                    Text("Saved without confirmation, these values remain unavailable for V2. They are manual entries, not Apple Health data.")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Manual Inputs")
            .onChange(of: subject) { _, _ in confirmed = false }
            .onChange(of: assessmentName) { _, _ in confirmed = false }
            .onChange(of: assessmentDate) { _, _ in confirmed = false }
            .onChange(of: previousDate) { _, _ in confirmed = false }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold).disabled(!isScoreValid)
                        .accessibilityIdentifier("saveManualInputsButton")
                }
            }
        }
    }

    @ViewBuilder
    private func timeField(title: String, value: Binding<Int?>, input: TimeInput) -> some View {
        VStack(spacing: 0) {
            Button {
                if value.wrappedValue == nil { value.wrappedValue = 0 }
                openPicker = openPicker == input ? nil : input
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.caption).foregroundStyle(.secondary)
                        Text(formattedDuration(value.wrappedValue)).font(.body.weight(.medium))
                    }
                    Spacer()
                    Text("manual").font(.caption).foregroundStyle(.tertiary)
                    Image(systemName: openPicker == input ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold)).foregroundStyle(.tertiary).accessibilityHidden(true)
                }
                .padding(.horizontal, 14).padding(.vertical, 11).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if openPicker == input {
                Divider()
                DurationWheelPicker(hours: hoursBinding(for: value), minutes: minutesBinding(for: value))
            }
        }
        .background(card, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(openPicker == input ? Color.accentColor.opacity(0.45) : border) }
    }

    private func hoursBinding(for total: Binding<Int?>) -> Binding<Int> {
        Binding(
            get: { ManualDuration.parts(from: total.wrappedValue ?? 0)?.hours ?? 0 },
            set: { hours in
                let minutes = ManualDuration.parts(from: total.wrappedValue ?? 0)?.minutes ?? 0
                total.wrappedValue = ManualDuration.totalMinutes(hours: hours, minutes: minutes)
            }
        )
    }
    private func minutesBinding(for total: Binding<Int?>) -> Binding<Int> {
        Binding(
            get: { ManualDuration.parts(from: total.wrappedValue ?? 0)?.minutes ?? 0 },
            set: { minutes in
                let hours = ManualDuration.parts(from: total.wrappedValue ?? 0)?.hours ?? 0
                total.wrappedValue = ManualDuration.totalMinutes(hours: hours, minutes: minutes)
            }
        )
    }
    private func formattedDuration(_ totalMinutes: Int?) -> String {
        guard let totalMinutes, let parts = ManualDuration.parts(from: totalMinutes) else { return "Not entered" }
        return "\(parts.hours)h \(parts.minutes)m"
    }
    private func save() {
        let trimmedScore = previousScoreText.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = trimmedScore.isEmpty ? nil : PreviousScoreInput.parse(trimmedScore)
        let calendar = Calendar.current
        let now = Date()
        let context = V2PredictionContext(subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            assessmentName: assessmentName.trimmingCharacters(in: .whitespacesAndNewlines), assessmentDate: assessmentDate,
            previousDate: previousDate, manualDay: manualDay,
            timeZoneIdentifier: sourceTimeZone, sameSubjectConfirmed: confirmed,
            nextIndividualAssessmentConfirmed: confirmed, latestComparablePriorConfirmed: confirmed)
        if confirmed, let issue = context.issue(now: now, calendar: calendar) { saveIssue = issue; return }
        if state.saveManualInputs(studyMinutes: draftStudyMinutes, screenTimeMinutes: draftScreenTimeMinutes, previousScore: score,
                                  now: now, context: confirmed ? context : nil) {
            dismiss()
        }
    }
    private static func scoreText(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.rounded() == value ? String(Int(value)) : String(value)
    }
}

private struct ProfileAvatar: View {
    let imageData: Data?
    let initials: String
    let size: CGFloat
    let palette: ProfilePalette

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.accentText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(palette.accentSurface)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().stroke(palette.accentBorder, lineWidth: 1) }
    }
}

struct ProfilePalette {
    let colorScheme: ColorScheme
    init(_ colorScheme: ColorScheme) { self.colorScheme = colorScheme }
    var background: Color { colorScheme == .dark ? Color(red: 7/255, green: 11/255, blue: 18/255) : Color(red: 241/255, green: 244/255, blue: 248/255) }
    var card: Color { colorScheme == .dark ? .white.opacity(0.028) : .white }
    var border: Color { colorScheme == .dark ? .white.opacity(0.055) : Color(red: 221/255, green: 227/255, blue: 236/255) }
    var secondaryText: Color { colorScheme == .dark ? .white.opacity(0.5) : Color(red: 90/255, green: 107/255, blue: 130/255) }
    var tertiaryText: Color { colorScheme == .dark ? .white.opacity(0.5) : Color(red: 96/255, green: 112/255, blue: 135/255) }
    var accentText: Color { colorScheme == .dark ? Color(red: 155/255, green: 214/255, blue: 243/255) : Color(red: 11/255, green: 110/255, blue: 158/255) }
    var accentSurface: Color { colorScheme == .dark ? Color(red: 90/255, green: 200/255, blue: 240/255).opacity(0.06) : Color(red: 233/255, green: 244/255, blue: 251/255) }
    var accentBorder: Color { colorScheme == .dark ? Color(red: 122/255, green: 197/255, blue: 240/255).opacity(0.2) : Color(red: 195/255, green: 222/255, blue: 239/255) }
    var aiText: Color { colorScheme == .dark ? Color(red: 178/255, green: 168/255, blue: 245/255).opacity(0.85) : Color(red: 80/255, green: 68/255, blue: 176/255) }
    var aiSurface: Color { colorScheme == .dark ? Color(red: 139/255, green: 127/255, blue: 232/255).opacity(0.06) : Color(red: 242/255, green: 240/255, blue: 253/255) }
    var aiBorder: Color { colorScheme == .dark ? Color(red: 139/255, green: 127/255, blue: 232/255).opacity(0.16) : Color(red: 218/255, green: 212/255, blue: 246/255) }
    var positive: Color { colorScheme == .dark ? Color(red: 52/255, green: 199/255, blue: 123/255) : Color(red: 24/255, green: 122/255, blue: 70/255) }
    var warning: Color { colorScheme == .dark ? Color(red: 227/255, green: 162/255, blue: 60/255) : Color(red: 154/255, green: 102/255, blue: 8/255) }
    var warningText: Color { colorScheme == .dark ? Color(red: 235/255, green: 203/255, blue: 146/255).opacity(0.9) : Color(red: 122/255, green: 82/255, blue: 5/255) }
    var warningSurface: Color { colorScheme == .dark ? Color(red: 227/255, green: 162/255, blue: 60/255).opacity(0.07) : Color(red: 252/255, green: 243/255, blue: 228/255) }
    var warningBorder: Color { colorScheme == .dark ? Color(red: 227/255, green: 162/255, blue: 60/255).opacity(0.2) : Color(red: 237/255, green: 216/255, blue: 174/255) }
}
