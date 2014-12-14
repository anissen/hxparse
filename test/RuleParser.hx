
/*
Syntax:
if (condition) then (action)
if [(condition), (condition)] then [(action), (action)]
*/

/*
Testing:
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

*/

import hxparse.Parser;
import hxparse.ParserBuilder;
import hxparse.Lexer;
import hxparse.LexerTokenSource;
import hxparse.RuleBuilder;
using Lambda;

enum RuleToken {
    TString(s:String);
    TPIf;
    TPThen;
    TPBracketOpen;
    TPBracketClose;
    TPComma;
    TPOpen;
    TPClose;
    TEof;
}

enum RuleExpr {
    EPString(s:String);
    EPIfThen(e1:RuleExpr, e2:RuleExpr);
    EParenthesis(e:RuleExpr);
    EList(e:Array<RuleExpr>);
    EStatements(e:Array<RuleExpr>);
}

class RuleLexer extends Lexer implements RuleBuilder {
    static var buf:StringBuf;

    static public var tok = @:rule [
        "if" => TPIf,
        "then" => TPThen,
        "\\[" => TPBracketOpen,
        "\\]" => TPBracketClose,
        "," => TPComma,
        "\\(" => {
            buf = new StringBuf();
            lexer.token(string);
            TString(buf.toString());
        },
        "#[^\n\r]*" => lexer.token(tok), // comment
        "[\r\n\t ]" => lexer.token(tok), // whitespace
        "" => TEof
    ];

    static var string = @:rule [
        "\\)" => {
            lexer.curPos().pmax;
        },
        "[^\\)]" => {
            buf.add(lexer.current);
            lexer.token(string);
        },
    ];
}

class RuleParser extends Parser<LexerTokenSource<RuleToken>, RuleToken> implements ParserBuilder {
    public function parse() {
        return EStatements(parseStatements([])); 
    }

    function parseStatements(stm :Array<RuleExpr>) {
        return switch stream {
            case [TPIf, e1 = parsePart(), TPThen, e2 = parsePart()]:
                stm.push(EPIfThen(e1, e2));
                parseStatements(stm);
            case [TEof]: 
                stm;
        }
    }

    function parsePart() {
        return switch stream {
            case [TPBracketOpen, arr = array([])]:
                EList(arr);
            case [TPOpen, e = parsePart(), TPClose]:
                EParenthesis(e);
            case [TString(s)]:
                EPString(s);
        }
    }

    function array(acc:Array<RuleExpr>) {
        return switch stream {
            case [TPBracketClose]: acc;
            case [elt = parsePart()]:
                acc.push(elt);
                switch stream {
                    case [TPBracketClose]: acc;
                    case [TPComma]: array(acc);
                }
        }
    }
}

class RuleEvaluator {
    static public function eval(e:RuleExpr) :String {
        return switch(e) {
            case EPIfThen(e1, e2):
                'IF ${eval(e1)} THEN ${eval(e2)}';
            case EPString(e):
                '"$e"';
            case EParenthesis(e1):
                '(${eval(e1)})';
            case EList(eA):
                '${eA.map(eval).join(" AND ")}';
            case EStatements(eA):
                '${eA.map(eval).join("\n")}';
        }
    }
}

class RuleEvaluator2 {
    static public function eval(e:RuleExpr) :Dynamic {
        return switch(e) {
            case EPIfThen(e1, e2):
                { conditions: eval(e1), actions: eval(e2) };
            case EPString(e):
                e;
            case EParenthesis(e1):
                eval(e1);
            case EList(eA):
                eA.map(eval);
            case EStatements(eA):
                eA.map(eval);
        }
    }
}
