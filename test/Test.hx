class Test {
	static function main() {
        function testRule(correct :Bool, s :String) {
            var lexer = new RuleParser.RuleLexer(byte.ByteData.ofString(s));
            var ts = new hxparse.LexerTokenSource(lexer, RuleParser.RuleLexer.tok);
            var parser = new RuleParser(ts);
            try {
                var parsed = parser.parse();
                var actual = RuleParser.RuleEvaluator.eval(parsed);
                trace('\nINPUT:\n$s\nOUTPUT:\n$actual\n');
                return true;
            } catch (e :hxparse.ParserError) {
                trace('Parse error', e);
                return false;
            }
            // trace('Expected: $expected, Actual: $actual. Correct: ${expected == actual}');
        }
        testRule(true, 'if (x12) then (y34)');
        testRule(true, 'if [(x12), (z56)] then (y34)');
        testRule(false, '[(x12), (z56)]');
        testRule(true, 'if [(a), (b), (c)] then [(d), (e)]\nif (f) then (g)');
        testRule(true, 'if (a) then (b)\nif (c) then (d)');
        testRule(true, '# blah\nif (a) then (b)\n# here is a comment\nif (c) then (d)');

        return;

		var parser = new PrintfParser(byte.ByteData.ofString("Valu$$e: $-050.2f kg"));
		trace(parser.parse());

		var parser = new JSONParser(byte.ByteData.ofString('{ "key": [true, false, null], "other\tkey": [12, 12.1, 0, 0.1, 0.9e, 0.9E, 9E-] }'), "jsontest");
		trace(parser.parse());

		// Using haxe.Utf8
		var value = 'hello âê€𩸽ùあ𠀀ÊÀÁÂÃÄÅÆÇÈÉËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáãäåæçèéëìíîïðñòóôõöøúûüýþÿ№ unicode';
		var lexer = new UnicodeTestLexer( byte.ByteData.ofString( value ), 'uft8-test' );
		var tokens = [];

		try while (true) {
			tokens.push( lexer.token( UnicodeTestLexer.root ) );
		} catch (_e:Dynamic) {
			trace(_e);
		}
		trace( tokens );

		var numTests = 0;
		function eq(expected:Float, s:String) {
			++numTests;
			var lexer = new ArithmeticParser.ArithmeticLexer(byte.ByteData.ofString(s));
			var ts = new hxparse.LexerTokenSource(lexer, ArithmeticParser.ArithmeticLexer.tok);
			var parser = new ArithmeticParser(ts);
			var result = ArithmeticParser.ArithmeticEvaluator.eval(parser.parse());
			if (expected != result) {
				trace('Error in "$s"; expected $expected but was $result');
			}
		}
		eq(1, "1");
		eq(2, "1 + 1");
		eq(6, "2 * 3");
		eq(2, "6 / 3");
		eq(1.5, "3 / 2");
		eq(10, "2 * 3 + 4");
		eq(14, "2 * (3 + 4)");
		eq(18, "9 + (3 * 4) - 3 / (1 * 1)");
		eq(-9, "-9");
		eq(-12, "-(4 + 8)");
        eq(12, "--12");
		eq(8, "2*(3-(2+(-3)))");
		trace('Done $numTests tests');
	}
}
