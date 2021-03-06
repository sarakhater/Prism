install:
	swift build -Xswiftc -suppress-warnings -c release && \cp -rf .build/release/prism /usr/local/bin
build:
	swift build -Xswiftc -suppress-warnings -c release && \cp -rf .build/release/prism bin 
project:
	ruby Helpers/make_project.rb
clean:
	rm -rf Prism.xcodeproj
test:
	swift test -Xswiftc -suppress-warnings | xcpretty -c