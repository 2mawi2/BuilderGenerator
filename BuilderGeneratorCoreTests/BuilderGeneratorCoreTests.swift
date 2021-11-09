import XCTest
import Foundation

@testable import BuilderGeneratorCore

class BuilderGeneratorTests: XCTestCase {
    func test_generate_builder_for_struct() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
        }
        """
        // act
        let result = generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("struct MyProfileBuilder"), true)
    }
    
    func test_generate_builder_considers_all_fields_with_correct_default_values() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
        }
        """
        // act
        let result = generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var name: String = \"\""), true)
        XCTAssertEqual(result.contains("var age: Int = 0"), true)
    }
    
    func test_generate_builder_considers_all_fields_with_correct_default_values_all_possible_types() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
            let height: Float
            let height2: Double
            let isActive: Bool
            let friends: [String]
            let nullableFriends: [String]?
            var nullableName: String?
            var unknown: UnknownStructOrEnum
        }
        """
        // act
        let result = generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var name: String = \"\""), true)
        XCTAssertEqual(result.contains("var age: Int = 0"), true)
        XCTAssertEqual(result.contains("var height: Float = 0.0"), true)
        XCTAssertEqual(result.contains("var height2: Double = 0.0"), true)
        XCTAssertEqual(result.contains("var isActive: Bool = false"), true)
        XCTAssertEqual(result.contains("var friends: [String] = []"), true)
        XCTAssertEqual(result.contains("var nullableFriends: [String]?"), true)
        XCTAssertEqual(result.contains("var nullableName: String?"), true)
        XCTAssertEqual(result.contains("var unknown: UnknownStructOrEnum = UnknownStructOrEnumBuilder().build()"), true)
    }
    
    func test_generate_builder_can_handle_properties_of_sub_scope() {
        // arrange
        let content = """
            struct PersonalData: Codable, Equatable {
                
                var firstName: String?
            
                var fullName: String {
                    var fullName = PersonNameComponents()
                    fullName.givenName = firstName
                    fullName.middleName = middleName
                    fullName.familyName = lastName
                    return PersonNameFormatter.longNameFormatter.string(from: fullName)
                }
            }
            """
        // act
        let result = generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var firstName: String?"), true)
        XCTAssertFalse(result.contains("fullName"))
    }
    
    func test_generate_builder_can_handle_generics() {
        // arrange
        let content = """
        struct ContentPage<T:Codable>: Codable {
            var items: [T] = []
            var paging: ContentPaging?
        
            enum CodingKeys: String, CodingKey {
                case items = "data"
                case paging = "paging"
            }
        }
        """
        // act
        let result = generateBuilders(file: content)
        // assert
        XCTAssertTrue(result.contains("var items: [T] = []"))
        XCTAssertTrue(result.contains("var paging: ContentPaging?"))
        XCTAssertTrue(result.contains("struct ContentPageBuilder<T:Codable> {"))
    }
    
}
