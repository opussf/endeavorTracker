#!/usr/bin/env lua

require "wowTest"
test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/EndeavorTracker.toc" )

-- addon setup
function test.before()
	chatLog = {}
end
function test.after()
end

test.run()
