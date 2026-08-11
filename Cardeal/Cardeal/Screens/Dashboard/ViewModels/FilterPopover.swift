import SwiftUI


struct FilterPopover: View {

    @Binding var selectedPeople: Set<String>
    @Binding var selectedSubjects: Set<String>

    private let people = [
        "Leonardo Drummond",
        "Eduarda Vieira"
    ]

    private let subjects = [
        "Pagamentos",
        "Metas e planos",
        "Contratos",
        "Entregas",
        "Vendas",
        "Recursos Humanos"
    ]

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            Text("Filtrar por")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)

            Divider()
                .padding(.vertical, 8)

            filterSection(
                title: "Pessoas"
            ) {

                peopleFilters
            }

            filterSection(
                title: "Assuntos"
            ) {

                subjectFilters
            }
        }
        .padding(12)
        .frame(width: 294)
        .background(.white)
    }
}

private extension FilterPopover {

    @ViewBuilder
    func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(title)
                .font(.system(size: 14, weight: .medium))

            content()
        }
        .padding(.bottom, 12)
    }
}

private extension FilterPopover {

    var peopleFilters: some View {

        FlowLayout(
            spacing: 6
        ) {

            ForEach(people, id: \.self) { person in

                FilterChip(
                    title: person,
                    isSelected: selectedPeople.contains(person),
                    showsCloseButton: true
                ) {

                    togglePerson(person)
                }
            }
        }
    }
}

private extension FilterPopover {

    var subjectFilters: some View {

        FlowLayout(
            spacing: 6
        ) {

            ForEach(
                FilterSubject.allCases
            ) { subject in

                FilterChip(
                    title: subject.rawValue,
                    isSelected:
                        selectedSubjects.contains(
                            subject.rawValue
                        ),
                    showsCloseButton: false
                ) {

                    toggleSubject(
                        subject.rawValue
                    )
                }
            }
        }
    }

    func toggleSubject(_ subject: String) {

        if selectedSubjects.contains(subject) {
            selectedSubjects.remove(subject)
        } else {
            selectedSubjects.insert(subject)
        }
    }

    func togglePerson(_ person: String) {
        if selectedPeople.contains(person) {
            selectedPeople.remove(person)
        } else {
            selectedPeople.insert(person)
        }
    }
}

struct FilterChip: View {

    let title: String
    let isSelected: Bool
    let showsCloseButton: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: 5) {

                if showsCloseButton {

                    Image(
                        systemName: "xmark"
                    )
                    .font(.system(
                        size: 8,
                        weight: .medium
                    ))
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    Circle()
                        .stroke(
                            isSelected
                                ? Color.accentColor
                                : Color.secondary.opacity(0.6),
                            lineWidth: 1
                        )
                        .fill(
                            isSelected
                                ? Color.accentColor
                                : .clear
                        )
                        .frame(
                            width: 9,
                            height: 9
                        )
                }

                Text(title)
                    .font(.system(
                        size: 11,
                        weight: .regular
                    ))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 20)
            .background {
                Capsule()
                    .fill(
                        Color.accentColor
                            .opacity(0.08)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
