package ;

import haikan.Haikan;
import haikan.List;
import js.html.Document;

class Example1
{
    public static function main()
    {
        var result = sourceList([for (i in 1..100) i])
            .isolate(20)
            .map(function(x){ return x * x})
            .filter(function(x){ return x % 2 == 0 })
            .consume()
            .value();
        Document.write(result);
    }
}