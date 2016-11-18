//
//  morurunTests.swift
//  morurunTests
//
//  Created by watanabe on 2016/10/31.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import XCTest
import RxSwift

@testable import morurun

class morurunTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPosting() {
        let expection = self.expectation(description: #function)
        
        Posting
            .rx
            .updatePostings()
            .subscribe(onNext: { print($0) },
                       onError: {  XCTFail($0.localizedDescription) },
                       onCompleted: { expection.fulfill() },
                       onDisposed: nil)
            .addDisposableTo(self.disposeBag)
        
        self.waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, error.debugDescription)
        }
    }
    
    func testLocation() {
        let expection = self.expectation(description: #function)
        
        Location
            .rx
            .updateLocation()
            .subscribe(onNext: { print($0) },
                       onError: {  XCTFail($0.localizedDescription) },
                       onCompleted: { expection.fulfill() },
                       onDisposed: nil)
            .addDisposableTo(self.disposeBag)
        
        self.waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, error.debugDescription)
        }

    }
    
    func testRegistration() {
        let expection = self.expectation(description: #function)
        
        let registration = RegistrationDialogViewModel()
        registration.nickname.value = "ゆにっとてすとくん"
        registration
            .rx
            .requestRegistration()
            .subscribe(onNext: { print($0) },
                       onError: {  XCTFail($0.localizedDescription) },
                       onCompleted: { expection.fulfill() },
                       onDisposed: nil)
            .addDisposableTo(self.disposeBag)
        
        self.waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, error.debugDescription)
        }
    }
    
    func testPostImage() {
        let expection = self.expectation(description: #function)
        
        let posting = PostingViewModel()
        posting.comment.value = "ゆにっとてすとだにょん"
        posting.image.value = R.image.gear()
        posting
            .rx
            .postData()
            .subscribe(onNext: { print($0) },
                       onError: {  XCTFail($0.localizedDescription) },
                       onCompleted: { expection.fulfill() },
                       onDisposed: nil)
            .addDisposableTo(self.disposeBag)
        
        self.waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, error.debugDescription)
        }
    }
}
