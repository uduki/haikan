package ;

import haikan.Haikan;
import haxe.ds.Option;
import js.Browser;
import js.html.Document;

class Example1
{
    public static function main()
    {
        var result = PipeTools.sourceArray([for (i in 1...100) i])
            & PipeTools.isolate(20)
            & PipeTools.map(function(x){ return x * x; })
            & PipeTools.filter(function(x){ return x % 2 == 0; })
            ^ PipeTools.consume();
        switch (result) {
            case Some(list):
                Browser.document.write(list.toString());
            case None:
                Browser.document.write("進捗ダメです！");
        }
    }
}