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
    @State private var selectedTab: Tab = .timeline
    @State private var selectedMember: TeamMember?

    var body: some View {
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
                Picker("Conteúdo", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 340)

                Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 28)

            Divider()

            Group {
                switch selectedTab {
                case .timeline:
                    TeamTimelineView(activities: team.timeline)
                case .people:
                    TeamPeopleView(members: team.members, selectedMember: $selectedMember)
                }
            }
        }
        .frame(minWidth: 960, idealWidth: 1_160, minHeight: 620, idealHeight: 720)
        .onAppear {
            selectedMember = team.members.first
        }
    }
}

private struct TeamTimelineView: View {
    let activities: [TeamActivity]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    TeamTimelineRow(activity: activity, showsConnector: index < activities.count - 1)
                }
            }
            .padding(36)
        }
    }
}

private struct TeamTimelineRow: View {
    let activity: TeamActivity
    let showsConnector: Bool

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
                Label(activity.date, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
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
                Text(activity.category.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(categoryColor)
                Text(activity.title)
                    .font(.title3.weight(.semibold))
                Text(activity.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label(activity.participants.joined(separator: ", "), systemImage: "person.2")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 28)

            Spacer(minLength: 0)
        }
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
        Circle()
            .fill(highlighted ? Color.accentColor : Color.secondary.opacity(0.20))
            .overlay {
                Text(member.initials)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(highlighted ? .white : .primary)
            }
            .frame(width: size, height: size)
    }
}
