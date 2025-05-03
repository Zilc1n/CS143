(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class StackCommand inherits IO {
    getChar() : String {
        "Get Char"
    };

    getInt() : Int {
        0
    };

    execute(node : StackNode) : StackNode {
        node
    };

    setInt(num : Int) : Int {
        0
    };

    display() : String {
        getChar()
    };
};

class IntCommand inherits StackCommand {
    value : Int;
    trans : A2I <- new A2I;

    getChar() : String {
        trans.i2a(value)
    };

    getInt() : Int {
        value
    };

    setInt(num : Int) : Int {
        value <- num
    };
};

class PlusCommand inherits StackCommand {
    getChar() : String {
        "+"
    };

    execute(node : StackNode) : StackNode {
        {
            if not (isvoid node.getNext()) then {
                if not (isvoid node.getNext().getNext()) then {
                    let n1 : StackNode <- node.getNext(),
                        n2 : StackNode <- n1.getNext() in {
                            {
                                n2.getCommand().setInt(n1.getCommand().getInt() + n2.getCommand().getInt());
                                n2;
                            };
                    };
                }
                else
                    0
                fi;
            }
            else 
                0
            fi;
            node.getNext().getNext();
        }
    };
};

class SwapCommand inherits StackCommand {
    getChar() : String {
        "s"
    };
    execute(node : StackNode) : StackNode {
        let tmp : StackNode <- node.getNext().getNext() in {
            {
                node.getNext().setNext(tmp.getNext());
                tmp.setNext(node.getNext());
                tmp;
            };
        }
    };
};

class StackNode {
    command : StackCommand;
    next : StackNode;

    init(co : StackCommand, ne : StackNode) : StackNode {
        {
            command <- co;
            next <- ne;
        }
    };
    getNext() : StackNode {
        next
    };

    getCommand() : StackCommand {
        command
    };

    setNext(node : StackNode) : StackNode {
        next <- node
    };
};

class Stack inherits IO {
    nil : StackNode;
    head : StackNode;
    trans : A2I <- new A2I;

    push(str : String) : StackNode {
        {
            let tmp : StackNode <- head in {
                head <- new StackNode;
                if str = "+" then
                    head.init(new PlusCommand, tmp)
                else
                    if str = "s" then 
                        head.init(new SwapCommand, tmp)
                    else {
                        head.init(new IntCommand, tmp);
                        head.getCommand().setInt(trans.a2i(str));
                    }
                    fi
                fi;
            };
            head;
        }
    };

    pop() : StackNode {
        if not (isvoid head) then
            head <- head.getCommand().execute(head)
        else 
            head
        fi
    };

    show() : Object {
        if not (isvoid head) then
            let ptr : StackNode <- head in 
                while not (isvoid ptr) loop {
                    {
                        out_string(ptr.getCommand().display());
                        out_string(" ");
                        ptr <- ptr.getNext();
                    };
                }
                pool
        else
            0
        fi
    };
};

class Main inherits IO{
    cmd : String;

    main() : Object {
        let stack : Stack <- new Stack in {
            cmd <- promat();
            while not cmd = "x" loop {
                if cmd = "e" then 
                    stack.pop()
                else 
                    if cmd = "d" then {
                        stack.show();
                        newline();
                    }
                    else 
                        stack.push(cmd)
                    fi
                fi;
                cmd <- promat();
            }
            pool;
            if cmd = "x" then
                out_string("stop\n")
            else
                0
            fi;
        }
    };

    promat() : String {
        {
            out_string(">");
            in_string();
        }
    };

    newline() : Object {
        out_string("\n")
    };
};
