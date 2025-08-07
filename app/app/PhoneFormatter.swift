import Foundation

struct Country {
    let code: String
    let dialCode: String
    let name: String
    let flag: String
    
    static let all = [
        Country(code: "US", dialCode: "+1", name: "United States", flag: "🇺🇸"),
        Country(code: "CA", dialCode: "+1", name: "Canada", flag: "🇨🇦"),
        Country(code: "GB", dialCode: "+44", name: "United Kingdom", flag: "🇬🇧"),
        Country(code: "AU", dialCode: "+61", name: "Australia", flag: "🇦🇺"),
        Country(code: "DE", dialCode: "+49", name: "Germany", flag: "🇩🇪"),
        Country(code: "FR", dialCode: "+33", name: "France", flag: "🇫🇷"),
        Country(code: "IN", dialCode: "+91", name: "India", flag: "🇮🇳"),
        Country(code: "CN", dialCode: "+86", name: "China", flag: "🇨🇳"),
        Country(code: "JP", dialCode: "+81", name: "Japan", flag: "🇯🇵"),
        Country(code: "KR", dialCode: "+82", name: "South Korea", flag: "🇰🇷"),
        Country(code: "BR", dialCode: "+55", name: "Brazil", flag: "🇧🇷"),
        Country(code: "MX", dialCode: "+52", name: "Mexico", flag: "🇲🇽"),
        Country(code: "RU", dialCode: "+7", name: "Russia", flag: "🇷🇺"),
        Country(code: "IT", dialCode: "+39", name: "Italy", flag: "🇮🇹"),
        Country(code: "ES", dialCode: "+34", name: "Spain", flag: "🇪🇸"),
        Country(code: "NL", dialCode: "+31", name: "Netherlands", flag: "🇳🇱"),
        Country(code: "SE", dialCode: "+46", name: "Sweden", flag: "🇸🇪"),
        Country(code: "NO", dialCode: "+47", name: "Norway", flag: "🇳🇴"),
        Country(code: "DK", dialCode: "+45", name: "Denmark", flag: "🇩🇰"),
        Country(code: "FI", dialCode: "+358", name: "Finland", flag: "🇫🇮")
    ]
    
    static let `default` = Country.all.first { $0.code == "US" }!
}

class PhoneFormatter {
    static func format(_ number: String, for country: Country) -> String {
        let cleaned = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        switch country.code {
        case "US", "CA":
            return formatNANP(cleaned)
        case "GB":
            return formatUK(cleaned)
        case "DE":
            return formatGermany(cleaned)
        case "FR":
            return formatFrance(cleaned)
        case "IN":
            return formatIndia(cleaned)
        default:
            return formatDefault(cleaned)
        }
    }
    
    private static func formatNANP(_ number: String) -> String {
        let digits = Array(number)
        switch digits.count {
        case 0...3:
            return String(digits)
        case 4...6:
            return "\(String(digits[0...2])) \(String(digits[3...]))"
        case 7...10:
            let areaCode = String(digits[0...2])
            let exchange = String(digits[3...5])
            let number = String(digits[6...])
            return "\(areaCode) \(exchange) \(number)"
        default:
            let areaCode = String(digits[0...2])
            let exchange = String(digits[3...5])
            let number = String(digits[6...9])
            return "\(areaCode) \(exchange) \(number)"
        }
    }
    
    private static func formatUK(_ number: String) -> String {
        let digits = Array(number)
        switch digits.count {
        case 0...4:
            return String(digits)
        case 5...7:
            return "\(String(digits[0...3])) \(String(digits[4...]))"
        case 8...11:
            return "\(String(digits[0...3])) \(String(digits[4...6])) \(String(digits[7...]))"
        default:
            return "\(String(digits[0...3])) \(String(digits[4...6])) \(String(digits[7...10]))"
        }
    }
    
    private static func formatGermany(_ number: String) -> String {
        let digits = Array(number)
        switch digits.count {
        case 0...3:
            return String(digits)
        case 4...6:
            return "\(String(digits[0...2])) \(String(digits[3...]))"
        case 7...11:
            return "\(String(digits[0...2])) \(String(digits[3...5])) \(String(digits[6...]))"
        default:
            return "\(String(digits[0...2])) \(String(digits[3...5])) \(String(digits[6...10]))"
        }
    }
    
    private static func formatFrance(_ number: String) -> String {
        let digits = Array(number)
        if digits.count <= 10 {
            return digits.enumerated().reduce("") { result, element in
                let (index, digit) = element
                return result + (index > 0 && index % 2 == 0 ? " " : "") + String(digit)
            }
        }
        return String(digits[0...9].enumerated().reduce("") { result, element in
            let (index, digit) = element
            return result + (index > 0 && index % 2 == 0 ? " " : "") + String(digit)
        })
    }
    
    private static func formatIndia(_ number: String) -> String {
        let digits = Array(number)
        switch digits.count {
        case 0...5:
            return String(digits)
        case 6...10:
            return "\(String(digits[0...4])) \(String(digits[5...]))"
        default:
            return "\(String(digits[0...4])) \(String(digits[5...9]))"
        }
    }
    
    private static func formatDefault(_ number: String) -> String {
        let digits = Array(number)
        return digits.enumerated().reduce("") { result, element in
            let (index, digit) = element
            return result + (index > 0 && index % 3 == 0 ? " " : "") + String(digit)
        }
    }
    
    static func getFullNumber(countryCode: String, phoneNumber: String) -> String {
        return countryCode + phoneNumber.replacingOccurrences(of: " ", with: "")
    }
}