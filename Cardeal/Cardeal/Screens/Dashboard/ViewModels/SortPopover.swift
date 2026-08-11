//
//  SortPopover.swift
//  Cardeal
//
//  Created by Beatriz Cazatti on 11/08/26.
//
import SwiftUI

struct SortPopover: View {

    @Binding var selection: SortOption

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            Text("Ordenar por")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 12)

            VStack(spacing: 0) {

                ForEach(SortOption.allCases) { option in

                    SortOptionRow(
                        option: option,
                        isSelected: selection == option
                    ) {
                        selection = option
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 180)
        .padding(.bottom, 6)
        .background(.white)
    }
}

struct SortOptionRow: View {

    let option: SortOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: 8) {

                Image(
                    systemName: isSelected
                        ? "checkmark"
                        : ""
                )
                .font(.system(
                    size: 13,
                    weight: .semibold
                ))
                .frame(
                    width: 16,
                    alignment: .center
                )

                Text(option.title)
                    .font(.system(
                    size: 14
                    ))

                Spacer()
            }
            .foregroundStyle(.primary)
            .frame(
                maxWidth: .infinity,
                minHeight: 28
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }
}
