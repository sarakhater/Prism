//
//  TemplateParserSpec.swift
//  Prism
//
//  Created by Shai Mishali on 30/05/2019.
//

import Foundation
import Quick
import Nimble
import SnapshotTesting
@testable import PrismCore

class TemplateParserSpec: QuickSpec {
    override func spec() {
        describe("Color Loop") {
            it("should produce valid output") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let template = """
                /// This file was generated using Prism, Gett's Design System code generator.
                /// https://github.com/GettEngineering/Prism

                fake line 1
                fake line 2

                Some Structure {
                    {{% FOR color %}}
                    {{%color.identity.camelcase%}}, {{%color.identity.snakecase%}} = {{%color.r%}}, {{%color.g%}}, {{%color.b%}}, {{%color.a%}}, {{%color.argb%}}, {{%color.ARGB%}}, {{%color.rgb%}}, {{%color.RGB%}}
                    {{% END color %}}
                }
                """

                assertSnapshot(matching: try! parser.parse(template: template),
                               as: .lines,
                               named: "Color Loop should provide valid output")
            }
        }

        describe("Text Styles Loop") {
            it("should produce valid output") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let template = """
                /// This file was generated using Prism, Gett's Design System code generator.
                /// https://github.com/GettEngineering/Prism

                fake line 1
                fake line 2

                Some Structure {
                    {{% FOR textStyle %}}
                    {{%textStyle.identity.camelcase%}}, {{%textStyle.identity.snakecase%}} = {{%textStyle.fontName%}}, {{%textStyle.fontSize%}}, {{%textStyle.color.identity.camelcase%}}, {{%textStyle.color.identity.snakecase%}}, {{%textStyle.color.rgb%}}, {{%textStyle.color.argb%}}, {{%textStyle.color.r%}}, {{%textStyle.color.g%}}, {{%textStyle.color.b%}}, {{%textStyle.color.a%}}
                    {{% END textStyle %}}
                }
                """

                assertSnapshot(matching: try! parser.parse(template: template),
                               as: .lines,
                               named: "Text Styles Loop should provide valid output")
            }
        }

        describe("Open loop with no closing") {
            it("should throw error") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let template = """
                /// This file was generated using Prism, Gett's Design System code generator.
                /// https://github.com/GettEngineering/Prism

                fake line 1
                fake line 2

                Some Structure {
                    {{% FOR color %}}
                    xyz
                }
                """

                expect { try parser.parse(template: template) }
                    .to(throwError(TemplateParser.Error.openLoop(identifier: "color")))
            }
        }

        describe("Unknown Loop") {
            it("should throw error") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let template = """
                /// This file was generated using Prism, Gett's Design System code generator.
                /// https://github.com/GettEngineering/Prism

                fake line 1
                fake line 2

                Some Structure {
                    {{% FOR whatever %}}
                    xyz
                    {{% END whatever %}}
                }
                """

                expect { try parser.parse(template: template) }
                    .to(throwError(TemplateParser.Error.unknownLoop(identifier: "whatever")))
            }
        }

        describe("Unknown Token") {
            it("should throw error") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let token = UUID().uuidString
                let template = "{{%\(token)%}}"

                expect { try parser.parse(template: template) }
                    .to(throwError(TemplateParser.Error.unknownToken(token: token)))
            }
        }

        describe("Errors") {
            context("localized description") {
                it("should have valid descriptions") {
                    let errors: [TemplateParser.Error] = [.openLoop(identifier: "color"),
                                                          .unknownLoop(identifier: "fake"),
                                                          .unknownToken(token: "fake"),
                                                          .prohibitedIdentities(identities: "fake1, fake2")]

                    let descriptions = errors.map { "\($0)" }
                    let expectedDescriptions = [
                        "Detected FOR loop 'color' with no closing END",
                        "Illegal FOR loop identifier 'fake'",
                        "Illegal token in template 'fake'",
                        "Prohibited identities 'fake1, fake2' can't be used"
                    ]

                    expect(descriptions) == expectedDescriptions
                }
            }
        }

        describe("Token") {
            context("unknown token") {
                it("should return nil") {
                    let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                    let project = try! projectResult.get()
                    expect(TemplateParser.Token(rawToken: UUID().uuidString,
                                                color: project.colors[0])).to(beNil())
                    expect(TemplateParser.Token(rawToken: UUID().uuidString,
                                                textStyle: project.textStyles[0],
                                                colors: project.colors)).to(beNil())
                }
            }

            context("unknown color identity") {
                it("should return nil token") {
                    let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                    let project = try! projectResult.get()
                    expect(TemplateParser.Token(rawToken: "textStyle.color.identity.camelcase",
                                                textStyle: project.textStyles[0],
                                                colors: [])).to(beNil())
                    expect(TemplateParser.Token(rawToken: "textStyle.color.identity.snakecase",
                                                textStyle: project.textStyles[0],
                                                colors: [])).to(beNil())
                }
            }
        }

        describe("Transormations") {
            it("should produce valid output") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()
                let parser = TemplateParser(project: project)

                let template = """
                {{% FOR textStyle %}}
                {{%textStyle.identity.camelcase|lowercase%}}
                {{%textStyle.identity.snakecase|uppercase%}}
                {{%textStyle.fontName|uppercase%}}
                {{%textStyle.fontName|replace(-,_)%}}
                {{%textStyle.fontName|lowercase|replace(-,_)%}}
                ==============================================
                {{% END textStyle %}}
                """

                assertSnapshot(matching: try! parser.parse(template: template),
                               as: .lines,
                               named: "Transformations should provide valid output")
            }

            context("unknown transformation") {
                it("should return nil") {
                    expect(TemplateParser.Transformation(rawValue: UUID().uuidString)).to(beNil())
                }
            }
        }

        describe("Prohibited Identifiers") {
            let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
            let project = try! projectResult.get()

            context("camel cased") {
                it("should throw an error") {
                    let configuration = PrismCore.Configuration(reservedColors: ["blueSky", "clearReddish"],
                                                                reservedTextStyles: ["body", "largeHeading"])
                    let parser = TemplateParser(project: project, configuration: configuration)

                    expect { try parser.parse(template: "") }
                        .to(throwError(TemplateParser.Error.prohibitedIdentities(identities: "blueSky, clearReddish, body, largeHeading")))
                }
            }

            context("snake cased") {
                it("should throw an error") {
                    let configuration = PrismCore.Configuration(reservedColors: ["blue_sky", "clear_reddish"],
                                                                reservedTextStyles: ["body", "large_heading"])
                    let parser = TemplateParser(project: project, configuration: configuration)

                    expect { try parser.parse(template: "") }
                        .to(throwError(TemplateParser.Error.prohibitedIdentities(identities: "blue_sky, clear_reddish, body, large_heading")))
                }
            }
        }
    }
}