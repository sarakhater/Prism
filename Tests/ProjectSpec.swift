//
//  ProjectSpec.swift
//  Prism
//
//  Created by Shai Mishali on 22/05/2019.
//

import Foundation
import Quick
import Nimble
import SnapshotTesting
@testable import PrismCore

class ProjectSpec: QuickSpec {
    override func spec() {
        describe("project snapshot") {
            it("is valid") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()

                assertSnapshot(matching: "\(project.debugDescription)",
                               as: .lines,
                               named: "project snapshot is valid")
            }
        }

        describe("project decoding from JSON") {
            context("successful") {
                it("should suceed and return valid Project") {
                    let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                    let project = try! projectResult.get()

                    expect(project.id) == "5xxad123dsadasxsaxsa"
                    expect(project.name) == "Fake Project Test"
                    expect(project.colors.map { $0.argbValue }.joined(separator: ", ")) == "#ccdf6369, #ff62b6df"
                    expect(project.textStyles.map { $0.name }.joined(separator: ", ")) == "Large Heading, Body"

                    let encoded = try! project.encode()
                    let decoded = try! Project.decode(from: encoded)

                    expect(project) == decoded
                }
            }

            context("failed") {
                it("should fail decoding") {
                    let projectResult = PrismAPI(jwtToken: "fake").mock(type: .faultyJSON)

                    guard case .failure = projectResult else {
                        fail("Expected error, got \(projectResult)")
                        return
                    }

                    expect(try? projectResult.get()).to(beNil())
                }
            }
        }

        describe("failed server response") {
            it("should return failed result") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .failure)

                guard case .failure = projectResult else {
                    fail("Expected error, got \(projectResult)")
                    return
                }

                expect(try? projectResult.get()).to(beNil())
            }
        }

        describe("invalid project ID causing invalid API URL") {
            it("should fail with error") {
                var result: PrismAPI.ProjectResult?
                PrismAPI(jwtToken: "dsadas").getProject(id: "|||") { res in result = res }

                switch result {
                case .some(.failure(let error as PrismAPI.Error)):
                    expect(error) == .invalidProjectId
                    expect(error.description) == "The provided project ID can't be used to construct a API URL"
                default:
                    fail("Expected invalid project ID error, got \(String(describing: result))")
                }
            }
        }

        describe("description") {
            it("should not be empty") {
                let projectResult = PrismAPI(jwtToken: "fake").mock(type: .successful)
                let project = try! projectResult.get()

                expect(project.description).toNot(beEmpty())
            }
        }
    }
}