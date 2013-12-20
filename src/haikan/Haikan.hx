package haikan;

import haxe.ds.Option;

abstract Haikan<I, O, R>(Pipe<I, O, R>)
{
    inline function new(pipe: Pipe<I,O,R>)
        this = pipe;

    @:from static public inline function fromPipe(pipe: Pipe<I,O,R>)
    {
        return new Haikan(pipe);
    }

    @:to public inline function toPipe(): Pipe<I,O,R>
        return this;

    @:op(A & B) static public function wrap<LI, RI, RO, RR>(lhs: Haikan<LI, RI, Void>, rhs: Haikan<RI, RO, RR>): Haikan<RI, RO, RR>
    {
        return rhs.toPipe().setSource(lhs.toPipe());
    }

    @:op(A ^ B) static public function consume<LI, RI, RR>(lhs: Haikan<LI, RI, Void>, rhs: Haikan<RI, Void, RR>): Option<RR>
    {
        return rhs.toPipe().setSource(lhs.toPipe()).run();
    }
}

enum Result<T>
{
    Continue;
    Done(v: Option<T>);
}

// 実体はPipeなのだが、余計な情報を削ぎ落した型で表す。後で変更する時に困らない。
typedef Context<I,O> = {
    public function await(): Option<I>;
    public function push(output: O): Void;
}

typedef PipeSource<I> = {
    public function get(): Option<I>;
}

// Contextはデータの取得とデータの送出を行うための物
// 戻り値は結果を表す。結果を返す必要が無いならずっとContinueしてればいい。
typedef PipeFunc<I,O,R> = Context<I,O> -> Result<R>

class Pipe<I, O, R>
{
    var pipe: Option<PipeSource<I>>;
    var queue: List<O>;
    var pf: PipeFunc<I,O,R>;

    public function new(f: PipeFunc<I,O,R>)
    {
        this.pf = f;
        this.pipe = None;
        this.queue = new List<O>();
    }

    public function get(): Option<O>
    {
        next();
        var t = queue.pop();
        return if (t != null) Some(t) else None;
    }

    public function setSource(src: PipeSource<I>): Pipe<I, O, R>
    {
        pipe = Some(src);
        return this;
    }

    // 戻り値を作成する関数
    public function run(): Option<R>
    {
        switch (pf(this)) {
            case Continue: return run();
            case Done(r): return r;
        }
    }

    // InputをOutputへ変換する関数
    public function next(): Void
    {
        switch (pf(this)) {
            case Continue:
                return;
            case Done(r):
                pipe = None;
                return;
        }
    }

    public function await(): Option<I>
    {
        return switch (pipe) {
            case Some(src): src.get();
            case None: None;
        }
    }

    public function push(o: O): Void
    {
        queue.add(o);
        return;
    }
}

class PipeTools
{
    static public function sourceArray<O>(arr: Array<O>): Haikan<Void, O, Void>
    {
        var itr = arr.iterator();
        var pf = function(c: Context<Void,O>): Result<Void> {
            if (itr.hasNext()) {
                c.push(itr.next());
                return Continue;
            } else {
                return Done(None);
            }
        }
        return new Pipe(pf);
    }

    static public function map<I,O>(f: I -> O): Haikan<I,O,Void>
    {
        var pf = function(c: Context<I,O>): Result<Void> {
            switch (c.await()) {
                case Some(i): {
                    c.push(f(i));
                    return Continue;
                }
                case None:
                    return Continue;
            }
        }
        return new Pipe(pf);
    }

    static public function filter<I,I>(p: I -> Bool): Haikan<I,I,Void>
    {
        var pf = function(c: Context<I,I>): Result<Void> {
            var isNext = false;
            while (!isNext) {
                isNext = switch(c.await()) {
                    case Some(i):
                        if (p(i)) {
                            c.push(i);
                            true;
                        } else {
                            false;
                        }
                    case None: true;
                }
            }
            return Continue;
        }
        return new Pipe(pf);
    }

    static public function isolate<I,I>(length: Int): Haikan<I,I,Void>
    {
        var l = 0;
        var pf = function(c: Context<I,I>): Result<Void> {
            return switch (c.await()) {
                case Some(i):
                    if (l < length) {
                        c.push(i);
                        ++l;
                        Continue;
                    } else {
                        Done(None);
                    }
                case None: Done(None);
            }
        }
        return new Pipe(pf);
    }

    static public function consume<I,I>(): Haikan<I,Void,List<I>>
    {
        var pf = function(c: Context<I,Void>): Result<List<I>> {
            var list = new List<I>();
            var isNext = true;
            while (isNext) {
                switch (c.await()) {
                    case Some(i): list.add(i);
                    case None: isNext = false;
                }
            }
            return Done(Some(list));
        }
        return new Pipe(pf);
    }
}
