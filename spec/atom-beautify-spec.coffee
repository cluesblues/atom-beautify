Beautifiers = require "../src/beautifiers"
beautifiers = new Beautifiers()
Beautifier = require "../src/beautifiers/beautifier"
Languages = require('../src/languages/')
_ = require('lodash')

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

# Check if Windows
isWindows = process.platform is 'win32' or
  process.env.OSTYPE is 'cygwin' or
  process.env.OSTYPE is 'msys'

describe "Atom-Beautify", ->

  beforeEach ->

    # Activate package
    waitsForPromise ->
      activationPromise = atom.packages.activatePackage('atom-beautify')
      # Force activate package
      pack = atom.packages.getLoadedPackage("atom-beautify")
      pack.activateNow()
      # Change logger level
      # atom.config.set('atom-beautify._loggerLevel', 'verbose')
      # Return promise
      return activationPromise

  describe "Beautifiers", ->

    beautifier = null

    beforeEach ->
      beautifier = new Beautifier()

    describe "Beautifier::run", ->

      it "should error when beautifier's program not found", ->
        expect(beautifier).not.toBe(null)
        expect(beautifier instanceof Beautifier).toBe(true)

        # waitsForRuns = (fn, message, timeout) ->
        #     isCompleted = false
        #     completed = ->
        #         console.log('completed')
        #         isCompleted = true
        #     runs ->
        #         console.log('runs')
        #         fn(completed)
        #     waitsFor(->
        #         console.log('waitsFor', isCompleted)
        #         isCompleted
        #     , message, timeout)
        #
        # waitsForRuns((cb) ->
        #     console.log('waitsForRuns', cb)
        #     setTimeout(cb, 2000)
        # , "Waiting for beautification to complete", 5000)

        waitsForPromise shouldReject: true, ->
          p = beautifier.run("program", [])
          expect(p).not.toBe(null)
          expect(p instanceof beautifier.Promise).toBe(true)
          cb = (v) ->
            # console.log(v)
            expect(v).not.toBe(null)
            expect(v instanceof Error).toBe(true)
            expect(v.code).toBe("CommandNotFound")
            expect(v.description).toBe(undefined, \
              'Error should not have a description.')
            return v
          p.then(cb, cb)
          return p

      it "should error with help description \
                when beautifier's program not found", ->
        expect(beautifier).not.toBe(null)
        expect(beautifier instanceof Beautifier).toBe(true)

        waitsForPromise shouldReject: true, ->
          help = {
            link: "http://test.com"
            program: "test-program"
            pathOption: "Lang - Test Program Path"
          }
          p = beautifier.run("program", [], help: help)
          expect(p).not.toBe(null)
          expect(p instanceof beautifier.Promise).toBe(true)
          cb = (v) ->
            # console.log(v)
            expect(v).not.toBe(null)
            expect(v instanceof Error).toBe(true)
            expect(v.code).toBe("CommandNotFound")
            expect(v.description).not.toBe(null)
            expect(v.description.indexOf(help.link)).not.toBe(-1)
            expect(v.description.indexOf(help.program)).not.toBe(-1)
            expect(v.description
              .indexOf(help.pathOption)).not.toBe(-1, \
              "Error should have a description.")
            return v
          p.then(cb, cb)
          return p

      it "should error with Windows-specific help description \
                when beautifier's program not found", ->
        expect(beautifier).not.toBe(null)
        expect(beautifier instanceof Beautifier).toBe(true)

        waitsForPromise shouldReject: true, ->
          help = {
            link: "http://test.com"
            program: "test-program"
            pathOption: "Lang - Test Program Path"
          }
          # Force to be Windows
          beautifier.isWindows = true
          terminal = 'CMD prompt'
          whichCmd = "where.exe"
          # Process
          p = beautifier.run("program", [], help: help)
          expect(p).not.toBe(null)
          expect(p instanceof beautifier.Promise).toBe(true)
          cb = (v) ->
            # console.log(v)
            expect(v).not.toBe(null)
            expect(v instanceof Error).toBe(true)
            expect(v.code).toBe("CommandNotFound")
            expect(v.description).not.toBe(null)
            expect(v.description.indexOf(help.link)).not.toBe(-1)
            expect(v.description.indexOf(help.program)).not.toBe(-1)
            expect(v.description
              .indexOf(help.pathOption)).not.toBe(-1, \
              "Error should have a description.")
            expect(v.description
              .indexOf(terminal)).not.toBe(-1, \
              "Error should have a description including \
                            '#{terminal}' in message.")
            expect(v.description
              .indexOf(whichCmd)).not.toBe(-1, \
              "Error should have a description including \
                            '#{whichCmd}' in message.")
            return v
          p.then(cb, cb)
          return p

      unless isWindows
        it "should error with Mac/Linux-specific help description \
                  when beautifier's program not found", ->
          expect(beautifier).not.toBe(null)
          expect(beautifier instanceof Beautifier).toBe(true)

          waitsForPromise shouldReject: true, ->
            help = {
              link: "http://test.com"
              program: "test-program"
              pathOption: "Lang - Test Program Path"
            }
            # Force to be Mac/Linux (not Windows)
            beautifier.isWindows = false
            terminal = "Terminal"
            whichCmd = "which"
            # Process
            p = beautifier.run("program", [], help: help)
            expect(p).not.toBe(null)
            expect(p instanceof beautifier.Promise).toBe(true)
            cb = (v) ->
              # console.log(v)
              expect(v).not.toBe(null)
              expect(v instanceof Error).toBe(true)
              expect(v.code).toBe("CommandNotFound")
              expect(v.description).not.toBe(null)
              expect(v.description.indexOf(help.link)).not.toBe(-1)
              expect(v.description.indexOf(help.program)).not.toBe(-1)
              expect(v.description
                .indexOf(terminal)).not.toBe(-1, \
                "Error should have a description including \
                              '#{terminal}' in message.")
              expect(v.description
                .indexOf(whichCmd)).not.toBe(-1, \
                "Error should have a description including \
                              '#{whichCmd}' in message.")
              return v
            p.then(cb, cb)
            return p

  describe "Options", ->

    editor = null
    beautifier = null
    workspaceElement = atom.views.getView(atom.workspace)
    beforeEach ->
      beautifier = new Beautifiers()
      waitsForPromise ->
        atom.workspace.open().then (e) ->
          editor = e
          expect(editor.getText()).toEqual("")

    beautifyEditor = (callback) ->
      isComplete = false
      beforeText = null
      delay = 500
      runs ->
        beforeText = editor.getText()
        atom.commands.dispatch workspaceElement, "atom-beautify:beautify-editor"
        setTimeout(->
          isComplete = true
        , delay)
      waitsFor ->
        isComplete

      runs ->
        afterText = editor.getText()
        expect(typeof beforeText).toBe('string')
        expect(typeof afterText).toBe('string')
        return callback(beforeText, afterText)

    describe "JavaScript", ->

      beforeEach ->

        waitsForPromise ->
          packName = 'language-javascript'
          atom.packages.activatePackage(packName)

        runs ->
          # Setup Editor
          code = "var hello='world';function(){console.log('hello '+hello)}"
          editor.setText(code)
          # console.log(atom.grammars.grammarsByScopeName)
          grammar = atom.grammars.selectGrammar('source.js')
          expect(grammar.name).toBe('JavaScript')
          editor.setGrammar(grammar)
          expect(editor.getGrammar().name).toBe('JavaScript')

          # See https://discuss.atom.io/t/solved-settimeout-not-working-firing-in-specs-tests/11427/17
          jasmine.unspy(window, 'setTimeout')

      afterEach ->
        atom.packages.deactivatePackages()
        atom.packages.unloadPackages()

      describe ".jsbeautifyrc", ->

      describe "Package settings", ->

        getOptions = (callback) ->
          options = null
          waitsForPromise ->
            console.log('beautifier', beautifier.getOptionsForPath, beautifier)
            allOptions = beautifier.getOptionsForPath(null, null)
            # Resolve options with promises
            return Promise.all(allOptions)
            .then((allOptions) ->
              options = allOptions
            )
          runs ->
            callback(options)

        it "should change indent_size to 1", ->
          atom.config.set('atom-beautify.js.indent_size', 1)

          getOptions (allOptions) ->
            expect(typeof allOptions).toBe('object')
            configOptions = allOptions[1]
            expect(typeof configOptions).toBe('object')
            expect(configOptions.js.indent_size).toBe(1)

            beautifyEditor (beforeText, afterText) ->
              # console.log(beforeText, afterText, editor)
              expect(afterText).toBe("""var hello = 'world';

              function() {
               console.log('hello ' + hello)
              }""")

        it "should change indent_size to 10", ->
          atom.config.set('atom-beautify.js.indent_size', 10)

          getOptions (allOptions) ->
            expect(typeof allOptions).toBe('object')
            configOptions = allOptions[1]
            expect(typeof configOptions).toBe('object')
            expect(configOptions.js.indent_size).toBe(10)

            beautifyEditor (beforeText, afterText) ->
              # console.log(beforeText, afterText, editor)
              expect(afterText).toBe("""var hello = 'world';

              function() {
                        console.log('hello ' + hello)
              }""")


describe "Languages", ->

  languages = null

  beforeEach ->
    languages = new Languages()

  describe "Languages::namespace", ->

    it "should verify that multiple languages do not share the same namespace", ->

      namespaceGroups = _.groupBy(languages.languages, "namespace")
      namespacePairs = _.toPairs(namespaceGroups)
      namespaceOverlap = _.filter(namespacePairs, ([namespace, group]) -> group.length > 1)
      console.log('namespaces', namespaceGroups, namespacePairs, namespaceOverlap)
      expect(namespaceOverlap.length).toBe(0, \
        "Language namespaces are overlapping.\n\
        Namespaces are unique: only one language for each namespace.\n"+
        _.map(namespaceOverlap, ([namespace, group]) -> "- '#{namespace}': Check languages #{_.map(group, 'name').join(', ')} for using namespace '#{namespace}'.").join('\n')
        )
