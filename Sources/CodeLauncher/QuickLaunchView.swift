import SwiftUI

struct QuickLaunchView: View {
    @Bindable var viewModel: LaunchViewModel
    var onDismiss: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            projectList
        }
        .frame(width: 600, height: 420)
        .onAppear { searchFocused = true }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search projects...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .focused($searchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var projectList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.filteredProjects.isEmpty {
                        Text("No projects found")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(viewModel.filteredProjects.enumerated()), id: \.element.id) { index, project in
                            ProjectRow(
                                project: project,
                                isSelected: index == viewModel.selectedIndex
                            )
                            .id(index)
                            .onTapGesture {
                                viewModel.openProject(project)
                                onDismiss()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(isSelected ? .white : .accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(project.path)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .contentShape(Rectangle())
    }
}
