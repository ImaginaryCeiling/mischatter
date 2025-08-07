import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.all
        } else {
            return Country.all.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.dialCode.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    List(filteredCountries, id: \.code) { country in
                        CountryRow(country: country, isSelected: country.code == selectedCountry.code) {
                            selectedCountry = country
                            dismiss()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("select country")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 16, weight: .light))
            
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("search countries")
                        .foregroundColor(.white.opacity(0.4))
                }
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CountryRow: View {
    let country: Country
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(country.flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(country.name)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white)
                    
                    Text(country.dialCode)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? .white.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CountryPickerView(selectedCountry: .constant(Country.default))
}