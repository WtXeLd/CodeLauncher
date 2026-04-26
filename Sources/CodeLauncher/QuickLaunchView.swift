import SwiftUI

struct QuickLaunchView: View {
    @Bindable var viewModel: LaunchViewModel
    var onDismiss: () -> Void
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().opacity(0.4)
            projectList
            Divider().opacity(0.4)
            footer
        }
        // Transparent so NSVisualEffectView behind shows through.
        // The subtle windowBackground tint ensures readability on any desktop color.
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
        .onAppear { searchFocused = true }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Search projects...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .focused($searchFocused)
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Project list

    private var projectList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if viewModel.filteredProjects.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(viewModel.filteredProjects.enumerated()), id: \.element.id) { index, project in
                            ProjectRow(
                                project: project,
                                isSelected: index == viewModel.selectedIndex,
                                shortcutIndex: index < 5 ? index + 1 : nil
                            )
                            .id(project.id)
                            .onTapGesture {
                                viewModel.openProject(project)
                                onDismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                if newIndex < viewModel.filteredProjects.count {
                    proxy.scrollTo(viewModel.filteredProjects[newIndex].id, anchor: .center)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No projects found")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 52)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("↑↓  navigate  ·  ↵  open  ·  ⇧↵  finder  ·  ⌘1-5  quick open  ·  esc  dismiss")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Spacer()
            if !viewModel.filteredProjects.isEmpty {
                Text("\(viewModel.filteredProjects.count) projects")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Row

private struct ProjectRow: View {
    let project: Project
    let isSelected: Bool
    var shortcutIndex: Int? = nil
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? Color.white.opacity(0.22) : Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .accentColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(project.path)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.72) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if let idx = shortcutIndex {
                Text("⌘\(idx)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AnyShapeStyle(.white.opacity(0.6)) : AnyShapeStyle(.tertiary))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.white.opacity(0.15) : Color.primary.opacity(0.06))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(
                    isSelected ? Color.accentColor :
                    isHovered  ? Color.primary.opacity(0.07) : Color.clear
                )
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
