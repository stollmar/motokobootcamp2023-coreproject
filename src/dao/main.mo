import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Principal "mo:base/Principal";


shared actor class Self() = this {
    
    stable var proposal_id: Nat = 0;
    stable var neuron_id: Nat = 0;
    stable var quadratic_voting : Bool = false;

    private let DISSOLVE_DELAY_BONUS_PER_SECOND = Float.div(1, (365 * 8 * 60 * 60 * 24));
    private let FOUR_YEARS_IN_MILLISECONDS : Int = 4 * 365 * 1000 * 60 * 60 * 24;
    private let AGE_BONUS_PER_SECOND : Float = Float.div(0.25, (4 * 365 * 60 * 60 * 24));

    private stable var _proposals : [(Nat, Proposal)] = [];
    private stable var _neurons : [(Principal, Neuron)] = [];
    private stable var _votes : [(Nat, [Vote])] = [];
    private var proposals : HashMap.HashMap<Nat, Proposal> = HashMap.fromIter<Nat, Proposal>(_proposals.vals(), 0, Nat.equal, Hash.hash);
    private var neurons : HashMap.HashMap<Principal, Neuron> = HashMap.fromIter<Principal, Neuron>(_neurons.vals(), 0, Principal.equal, Principal.hash);
    private var votes : HashMap.HashMap<Nat, [Vote]> = HashMap.fromIter<Nat, [Vote]>(_votes.vals(), 0, Nat.equal, Hash.hash);

    let webpage : actor { set_title : (Text) -> async ()} = actor("cgtel-uaaaa-aaaak-qbqyq-cai");

    public type NeuronStatus = {
        #Locked : {
            dissolve_delay : Int; // 8 years = 8 * 365 * 1000 * 60 * 60 * 24  | 6 months = 182 days
            time : Int;
        };
        #Dissolving : {
            dissolve_delay : Int;
            time : Int;
        };
        #Dissolved : {
            dissolve_delay : Int;
            time : Int;
        };
    };

    public type Neuron = {
        id : Nat;
        token_staking : Int;
        dissolve_delay : Int; // 8 years = 8 * 365 * 1000 * 60 * 60 * 24  | 6 months = 182 days
        createTime : Int;
        status : NeuronStatus;
    };
    public type Vote = {
        principal : Principal;
        v_power : Float;
        v_type : Bool;
    };
    public type Proposal = {
        name : Text;
        vote : {
            accept : Float;
            reject : Float;
        };
        state : Bool;
        startTime : Int;
        endTime : Int;
    };

    system func preupgrade() {
        _proposals := Iter.toArray(proposals.entries());
        _neurons := Iter.toArray(neurons.entries());
        _votes := Iter.toArray(votes.entries());
    };

    system func postupgrade() {
        _proposals := [];
        _neurons := [];
        _votes := [];
    };

    public shared (msg) func getPrincipal() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    public shared({caller}) func submit_proposal(p : Proposal) : async {#Ok : Proposal; #Err : Text} {
        // return #Err("Not implemented yet");
        proposal_id += 1;
        var proposal : Proposal = {
            name = p.name;
            vote = {
                accept = 0;
                reject = 0;
            };
            state = true;
            startTime = p.startTime;
            endTime = p.endTime;
        };
        proposals.put(proposal_id, proposal);
        return #Ok(p);
    };

    private func create_proposal(name : Text, startTime : Int, endTime : Int) : Proposal {
        return {
            name = name;
            vote = {
                accept = 0;
                reject = 0;
            };
            state = true;
            startTime = startTime;
            endTime = endTime;
        };
    };

    public query func get_proposal(id : Nat) : async ?Proposal {
        return proposals.get(id);
    };
    
    public query func get_all_proposals() : async [(Nat, Proposal)] {
        return Iter.toArray(proposals.entries());
    };

    private func update_proposal(id: Nat, name : Text, accept : Float, reject : Float, state : Bool, startTime : Int, endTime : Int) : async Proposal {
        var proposal : Proposal = {
            name = name;
            vote = {
                accept = accept;
                reject = reject;
            };
            state = state;
            startTime = startTime;
            endTime = endTime;
        };
        proposals.put(id, proposal);
        return proposal;
    };

    private func delete_proposal(id : Nat) : async ?Proposal {
        proposals.remove(id);
    };

    private func dissolve_delay_bonus(neuron : Neuron) : Float {
        switch (neuron.status) {
            case (#Locked(n)) {
                return 1 + (Float.fromInt(n.dissolve_delay) / 1000 * DISSOLVE_DELAY_BONUS_PER_SECOND);
            };
            case (#Dissolving(n)) {
                return 1 + ((Float.fromInt(n.dissolve_delay) - Float.fromInt(get_time_in_millisecond() - n.time)) / 1000 * DISSOLVE_DELAY_BONUS_PER_SECOND);
            };
            case (_) {
                return 0;
            };
        };
    };

    private func age_bonus(neuron : Neuron) : Float {
        // Float.sub(Float.fromInt(get_time_in_millisecond()), Float.fromInt(neuron.createTime));
        switch (neuron.status) {
            case (#Locked(n)) {
                var bonus_time = get_time_in_millisecond() - n.time;
                if (bonus_time > FOUR_YEARS_IN_MILLISECONDS) {
                    bonus_time := FOUR_YEARS_IN_MILLISECONDS;
                };
                return (1 + Float.div(Float.fromInt(bonus_time), 1000) * AGE_BONUS_PER_SECOND);
            };
            case (#Dissolving(n)) {
                var bonus_time = n.time - neuron.createTime;
                if (bonus_time > FOUR_YEARS_IN_MILLISECONDS) {
                    bonus_time := FOUR_YEARS_IN_MILLISECONDS;
                };
                return (1 + Float.div(Float.fromInt(bonus_time), 1000) * AGE_BONUS_PER_SECOND);
            };
            case (_) {
                return 1;
            };
        };
    };

    private func token_voting_calculate(neuron : Neuron) : Float {
        if (quadratic_voting) {
            return Float.pow(Float.fromInt(neuron.token_staking), 2);
        };
        return Float.fromInt(neuron.token_staking);
    };

    private func voting_power_calculate(p: Principal) : Float {
        switch(neurons.get(p)) {
            case (?neuron) {
                let voting_power = token_voting_calculate(neuron) * dissolve_delay_bonus(neuron) * age_bonus(neuron);
                return voting_power;
            };
            case _ {
                return Float.fromInt(0);
            };
        };
    };

    public shared(msg) func vote(principal: Principal, proposal_id : Nat, yes_or_no : Bool) : async {#Ok : (Float, Float); #Err : Text} {
        let caller = getPriorityCaller(msg.caller, principal);
        if (has_voted(caller, proposal_id)) {
            return #Err("You only vote 1 time");
        };
        switch(proposals.get(proposal_id)) {
            case(?p) { 
                if (p.state == false) {
                    return #Err("Proposal not allow to vote");
                };
                let voting_power = voting_power_calculate(caller);

                // put vote
                let vote : Vote = {
                    principal = caller;
                    v_power = voting_power;
                    v_type = yes_or_no;
                };
                var vote_arr = [vote];
                switch(votes.get(proposal_id)) {
                    case (?v) {
                        vote_arr := Array.append(v, vote_arr);
                        votes.put(proposal_id, vote_arr);
                    };
                    case (null) {
                        votes.put(proposal_id, vote_arr);
                    };
                };

                let proposal = vote_counting(p, vote_arr);
                let verified_proposal = verify_proposal_state(proposal);
                proposals.put(proposal_id, verified_proposal);
                
                //
                if (verified_proposal.vote.accept >= 100 or (verified_proposal.vote.accept >= verified_proposal.vote.reject and (Time.now()/1000000) >= verified_proposal.endTime)) {
                    await webpage.set_title(p.name);
                };
                return #Ok((proposal.vote.accept, proposal.vote.reject));
            };
            case(null) {
                return #Err("Proposal not found");
            };
        };
    };

    private func has_voted(p: Principal, proposal_id : Nat) : Bool {
        switch(votes.get(proposal_id)) {
            case (?v) {
                for (vote in v.vals()) {
                    if (vote.principal == p) {
                        return true;
                    };
                };
                return false;
            };
            case (null) {
                return false;
            };
        };
    };

    private func vote_counting(p: Proposal, votes : [Vote]) : Proposal {
        var accept : Float = 0;
        var reject : Float = 0;
        for (v in votes.vals()) {
            if (v.v_type) {
                accept += v.v_power;
            } else {
                reject += v.v_power;
            };
        };
        return {
            name = p.name;
            vote = {
                accept = accept;
                reject = reject;
            };
            state = p.state;
            startTime = p.startTime;
            endTime = p.endTime;
        };
    };

    private func verify_proposal_state(p: Proposal) : Proposal {
        if (p.vote.accept >= 100 or p.vote.reject >= 100 or (Time.now()/1000000) >= p.endTime) {
            return {
                name = p.name;
                vote = {
                    accept = p.vote.accept;
                    reject = p.vote.reject;
                };
                state = false;
                startTime = p.startTime;
                endTime = p.endTime;
            };
        };
        return p;        
    };

    public shared (msg) func create_neuron(principal: Principal, token_amount : Int, ddelay : Int) : async {#Ok : Neuron; #Err : Text} {
        let caller = getPriorityCaller(msg.caller, principal);
        switch (neurons.get(caller)) {
            case (?neuron) {
                let nr = {
                    id = neuron.id;
                    token_staking = token_amount;
                    dissolve_delay = ddelay;
                    createTime = get_time_in_millisecond();
                    status = #Locked({
                        dissolve_delay = ddelay;
                        time = get_time_in_millisecond();
                    });
                };
                neurons.put(caller, nr);
                return #Ok(nr);
            };
            case _ {
                neuron_id += 1;
                let nr = {
                    id = neuron_id;
                    token_staking = token_amount;
                    dissolve_delay = ddelay;
                    createTime = get_time_in_millisecond();
                    status = #Locked({
                        dissolve_delay = ddelay;
                        time = get_time_in_millisecond();
                    });
                };
                neurons.put(caller, nr);
                return #Ok(nr);
            };
        };
        return #Err("Neuron create failed");
    };

    private func get_time_in_millisecond() : Int {
        return (Time.now() / 1000000);
    };

    private func getPriorityCaller(principalAsCaller : Principal, principalFromParams : Principal) : Principal {
        if (Principal.isAnonymous(principalAsCaller)) {
            return principalFromParams;
        };
        return principalAsCaller;
    };

    public query (msg) func get_neuron(principal : Principal) : async {#Ok : Neuron; #Err : Text} {
        let caller = getPriorityCaller(msg.caller, principal);
        switch (neurons.get(caller)) {
            case (?n) return #Ok(n);
            case _ return #Err("Neuron not exist");
        };
    };

    public query func get_all_neurons() : async [(Principal, Neuron)] {
        return Iter.toArray(neurons.entries());
    };

    public query (msg) func get_voting_power(principal : Principal) : async {
            vote_power : Float;
            token_num : Float;
            dissolve_delay : Float;
            age : Float;
        } {
        let caller = getPriorityCaller(msg.caller, principal);
        switch(neurons.get(caller)) {
            case (?neuron) {
                return {
                    vote_power = voting_power_calculate(caller);
                    token_num = token_voting_calculate(neuron);
                    dissolve_delay = dissolve_delay_bonus(neuron);
                    age = age_bonus(neuron);
                };
            };
            case _ {
                return {
                    vote_power = 0;
                    token_num = 0;
                    dissolve_delay = 0;
                    age = 0;
                };
            };
        };
    };

    public shared (msg) func delete_newron(principal : Principal) : async () {
        let caller = getPriorityCaller(msg.caller, principal);
        neurons.delete(caller);
    };

    public shared (msg) func update_neuron(principal : Principal, neuron : Neuron) : async Neuron {
        let caller = getPriorityCaller(msg.caller, principal);
        neurons.put(caller, neuron);
        return neuron;
    };

    public shared (msg) func dissolve_neuron(principal : Principal) : async {#Ok : Neuron; #Err : Text} {
        let caller = getPriorityCaller(msg.caller, principal);
        switch(neurons.get(caller)) {
            case (?neuron) {
                switch (neuron.status) {
                    case (#Locked({})) {
                        let nr = {
                            id = neuron.id;
                            token_staking = neuron.token_staking;
                            dissolve_delay = neuron.dissolve_delay;
                            createTime = neuron.createTime;
                            status = #Dissolving({
                                dissolve_delay = neuron.dissolve_delay;
                                time = get_time_in_millisecond();
                            });
                        };
                        neurons.put(caller, nr);
                        return #Ok(nr)
                    };
                    case (_) {
                        return #Err("Neuron already dissolving");
                    };
                };
            };
            case (_) {
                return #Err("Neuron not exist");
            };
        };
    };

    public func get_votes(proposal_id : Nat) : async ?[Vote] {
        return votes.get(proposal_id);
    };
};