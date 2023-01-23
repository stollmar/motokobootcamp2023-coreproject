import Types "types";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import SHA256 "SHA256";

module Utils = {

    public type HashTree = Types.HashTree;
    public type Hash = Types.Hash;

    public func base64(b : Blob) : Text {
        let base64_chars : [Text] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"];
        let bytes = Blob.toArray(b);
        let pad_len = if (bytes.size() % 3 == 0) { 0 } else {3 - bytes.size() % 3 : Nat};
        let padded_bytes = Array.append(bytes, Array.tabulate<Nat8>(pad_len, func(_) { 0 }));
        var out = "";
        for (j in Iter.range(1,padded_bytes.size() / 3)) {
        let i = j - 1 : Nat; // annoying inclusive upper bound in Iter.range
        let b1 = padded_bytes[3*i];
        let b2 = padded_bytes[3*i+1];
        let b3 = padded_bytes[3*i+2];
        let c1 = (b1 >> 2          ) & 63;
        let c2 = (b1 << 4 | b2 >> 4) & 63;
        let c3 = (b2 << 2 | b3 >> 6) & 63;
        let c4 = (b3               ) & 63;
        out #= base64_chars[Nat8.toNat(c1)]
            # base64_chars[Nat8.toNat(c2)]
            # (if (3*i+1 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c3)] })
            # (if (3*i+2 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c4)] });
        };
        return out
    };

    public func cbor_tree(tree : HashTree) : Blob {
        let buf = Buffer.Buffer<Nat8>(100);

        // CBOR self-describing tag
        buf.add(0xD9);
        buf.add(0xD9);
        buf.add(0xF7);

        func add_blob(b: Blob) {
        // Only works for blobs with less than 256 bytes
        buf.add(0x58);
        buf.add(Nat8.fromNat(b.size()));
        for (c in Blob.toArray(b).vals()) {
            buf.add(c);
        };
        };

        func go(t : HashTree) {
        switch (t) {
            case (#empty)        { buf.add(0x81); buf.add(0x00); };
            case (#fork(t1,t2))  { buf.add(0x83); buf.add(0x01); go(t1); go (t2); };
            case (#labeled(l,t)) { buf.add(0x83); buf.add(0x02); add_blob(l); go (t); };
            case (#leaf(v))      { buf.add(0x82); buf.add(0x03); add_blob(v); };
            case (#pruned(h))    { buf.add(0x82); buf.add(0x04); add_blob(h); }
        }
        };

        go(tree);

        return Blob.fromArray(buf.toArray());
    };

    public func hash_tree(t : HashTree) : Hash {
        switch (t) {
            case (#empty) {
                h("\11ic-hashtree-empty");
            };
            case (#fork(t1,t2)) {
                h3("\10ic-hashtree-fork", hash_tree(t1), hash_tree(t2));
            };
            case (#labeled(l,t)) {
                h3("\13ic-hashtree-labeled", l, hash_tree(t));
            };
            case (#leaf(v)) {
                h2("\10ic-hashtree-leaf", v)
            };
            case (#pruned(h)) {
                h
            }
        }
    };

    public func h(b1 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        Blob.fromArray(d.sum());
    };

    public func h2(b1 : Blob, b2 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        d.write(Blob.toArray(b2));
        Blob.fromArray(d.sum());
    };

    public func h3(b1 : Blob, b2 : Blob, b3 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        d.write(Blob.toArray(b2));
        d.write(Blob.toArray(b3));
        Blob.fromArray(d.sum());
    };

}