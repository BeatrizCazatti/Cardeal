import SwiftUI

/// Folha que apresenta a linha do tempo e os membros de uma equipe.
struct TeamDetailSheet: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case timeline = "Linha do tempo"
        case people = "Pessoas"

        var id: Self { self }
    }

    let team: TeamDetail
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTheme) private var theme
    @State private var selectedTab: Tab = .timeline
    @State private var selectedMember: TeamMember?
    @State private var favoriteActivityIDs = Set<TeamActivity.ID>()
    @State private var featuredFavoriteID: TeamActivity.ID?
    @State private var timelineScrollTarget: TeamActivity.ID?

    private var featuredFavorite: TeamActivity? {
        guard let featuredFavoriteID else { return nil }
        return team.timeline.first { $0.id == featuredFavoriteID }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(team.name)
                        .font(.largeTitle.weight(.semibold))

                    Spacer()

                    Button("Fechar", systemImage: "xmark", action: { dismiss() })
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 36)
                .padding(.top, 32)
                .padding(.bottom, 22)

                HStack {
                    tabSelector

                    Spacer()
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 28)
            }
            .background(TeamDetailHeaderBackground(theme: theme))

            if let featuredFavorite {
                FavoriteActivityBanner(activity: featuredFavorite) {
                    navigateToFavorite(featuredFavorite.id)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
            }

            Divider()

            Group {
                switch selectedTab {
                case .timeline:
                    TeamTimelineView(
                        activities: team.timeline,
                        members: team.members,
                        favoriteActivityIDs: $favoriteActivityIDs,
                        scrollTarget: $timelineScrollTarget
                    ) { activityID in
                        toggleFavorite(activityID)
                    }
                case .people:
                    TeamPeopleView(members: team.members, selectedMember: $selectedMember)
                }
            }
        }
        .frame(minWidth: 960, idealWidth: 1_160, minHeight: 620, idealHeight: 720)
    }

    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { tab in
                Button {
                    select(tab)
                } label: {
                    Text(tab.rawValue)
                        .foregroundStyle(selectedTab == tab ? Color.tabButtonSelectedText : Color.tabButtonText)
                        .font(.title3.weight(selectedTab == tab ? .semibold : .regular))
                        .padding(.horizontal, 20)
                        .frame(minHeight: 44)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .background {
                    if selectedTab == tab {
                        Capsule(style: .continuous)
                            .fill(theme.accentColor)
                    }
                }
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func select(_ tab: Tab) {
        guard tab != selectedTab else { return }

        if tab == .people {
            selectedMember = nil
        }

        if reduceMotion {
            selectedTab = tab
        } else {
            withAnimation(.snappy(duration: 0.25)) {
                selectedTab = tab
            }
        }
    }

    private func toggleFavorite(_ activityID: TeamActivity.ID) {
        if favoriteActivityIDs.contains(activityID) {
            favoriteActivityIDs.remove(activityID)
            if featuredFavoriteID == activityID {
                featuredFavoriteID = favoriteActivityIDs.first
            }
        } else {
            favoriteActivityIDs.insert(activityID)
            featuredFavoriteID = activityID
        }
    }

    private func navigateToFavorite(_ activityID: TeamActivity.ID) {
        if selectedTab != .timeline {
            select(.timeline)
        }

        // Limpar antes de reaplicar permite repetir o atalho para o mesmo item.
        timelineScrollTarget = nil
        DispatchQueue.main.async {
            timelineScrollTarget = activityID
        }
    }
}

private struct TeamTimelineView: View {
    let activities: [TeamActivity]
    let members: [TeamMember]
    @Binding var favoriteActivityIDs: Set<TeamActivity.ID>
    @Binding var scrollTarget: TeamActivity.ID?
    let toggleFavorite: (TeamActivity.ID) -> Void
    @State private var highlightedActivityID: TeamActivity.ID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        TeamTimelineRow(
                            activity: activity,
                            members: members,
                            isFavorite: favoriteActivityIDs.contains(activity.id),
                            isHighlighted: highlightedActivityID == activity.id,
                            showsConnector: index < activities.count - 1
                        ) {
                            toggleFavorite(activity.id)
                        }
                        .id(activity.id)
                    }
                }
                .padding(36)
            }
            .onAppear {
                scroll(to: scrollTarget, using: proxy)
            }
            .onChange(of: scrollTarget) { _, newValue in
                scroll(to: newValue, using: proxy)
            }
        }
    }

    private func scroll(to target: TeamActivity.ID?, using proxy: ScrollViewProxy) {
        guard let target else { return }

        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.4)) {
                proxy.scrollTo(target, anchor: .center)
                highlightedActivityID = target
            }
            scrollTarget = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                guard highlightedActivityID == target else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    highlightedActivityID = nil
                }
            }
        }
    }
}

private struct TeamTimelineRow: View {
    let activity: TeamActivity
    let members: [TeamMember]
    let isFavorite: Bool
    let isHighlighted: Bool
    let showsConnector: Bool
    let toggleFavorite: () -> Void
    @Environment(\.appTheme) private var theme

    private var categoryColor: Color {
        switch activity.category {
        case .decision: .green
        case .task: .blue
        case .meeting: .orange
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .trailing, spacing: 10) {
                Text(activity.date)
                    .font(.subheadline)
                    .foregroundStyle(theme.accentColor.opacity(0.72))
            }
            .frame(width: 180, alignment: .trailing)

            VStack(spacing: 0) {
                Circle()
                    .fill(.secondary)
                    .frame(width: 9, height: 9)
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 1)
                    .frame(maxHeight: showsConnector ? .infinity : 0)
            }
            .frame(minHeight: 146, alignment: .top)

            VStack(alignment: .leading, spacing: 12) {
                Label(activity.category.rawValue, systemImage: activity.category.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(categoryColor)
                Text(activity.title)
                    .font(.title3.weight(.semibold))
                Text(activity.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    HStack(spacing: -8) {
                        ForEach(activity.participants, id: \.self) { participant in
                            ProfileAvatar(name: participant, size: 36)
                                .overlay(Circle().stroke(.background, lineWidth: 1))
                        }
                    }
                    .accessibilityHidden(true)

//                    Text(activity.participants.joined(separator: ", "))
//                        .font(.subheadline.weight(.medium))
//                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 28)

            Spacer(minLength: 12)

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isFavorite ? .yellow : theme.accentColor)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos")
            .accessibilityValue(isFavorite ? "Favorito" : "Não favorito")
        }
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isHighlighted ? theme.accentColor.opacity(0.12) : .clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isHighlighted ? theme.accentColor.opacity(0.45) : .clear, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

private struct FavoriteActivityBanner: View {
    let activity: TeamActivity
    let action: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundStyle(theme.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Favorito")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Favorito: \(activity.title)")
        .accessibilityHint("Vai para esta atividade na linha do tempo")
    }
}

private struct TeamPeopleView: View {
    let members: [TeamMember]
    @Binding var selectedMember: TeamMember?

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(members) { member in
                        TeamMemberCard(member: member, isSelected: selectedMember == member) {
                            selectedMember = member
                        }
                    }
                }
                .padding(36)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if let selectedMember {
                Divider()
                TeamMemberDetailView(member: selectedMember)
                    .frame(width: 330)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedMember)
    }
}

private struct TeamMemberCard: View {
    let member: TeamMember
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                TeamMemberAvatar(member: member, highlighted: isSelected, size: 92)
                Text(member.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(member.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 154, height: 190)
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TeamMemberDetailView: View {
    let member: TeamMember

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 14) {
                    TeamMemberAvatar(member: member, highlighted: false, size: 72)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(member.name).font(.title2.weight(.semibold))
                        Text(member.email).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    TeamMemberDetailRow(label: "Cargo", value: member.role, systemImage: "person.2")
                    TeamMemberDetailRow(label: "Contratado em", value: member.hiredDate, systemImage: "calendar")
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Últimas atividades").font(.headline)
                    ForEach(member.recentActivities, id: \.self) { activity in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(activity).font(.subheadline.weight(.semibold))
                            Label("5 ago, 2026", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Label("Projetos relacionados", systemImage: "briefcase")
                        .font(.headline)
                    ForEach(member.relatedProjects, id: \.self) { project in
                        Text(project).font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding(28)
        }
        .background(Color.accentColor.opacity(0.045))
    }
}

private struct TeamMemberDetailRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(label, systemImage: systemImage)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

private struct TeamMemberAvatar: View {
    let member: TeamMember
    let highlighted: Bool
    let size: CGFloat

    var body: some View {
        ProfileAvatar(name: member.name, highlighted: highlighted, size: size)
    }
}

/// Avatar compartilhado entre a timeline e a aba Pessoas. Quando fotos reais
/// forem adicionadas ao catálogo de assets, este é o único ponto a trocar a
/// representação de monograma pela imagem de perfil.
private struct ProfileAvatar: View {
    let name: String
    var highlighted = false
    let size: CGFloat

    private var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }

    private var color: Color {
        switch name.unicodeScalars.first?.value ?? 0 {
        case 65...70: .cardealPurple
        case 71...76: .cardealGreen
        case 77...82: .cardealOrange
        default: .cardealBlue
        }
    }

    var body: some View {
        Circle()
            .fill(highlighted ? Color.primaryAction : color.opacity(0.20))
            .overlay {
                Text(initials)
                    .font(size >= 60 ? .title3.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(highlighted ? .white : color)
            }
            .frame(width: size, height: size)
    }
}

