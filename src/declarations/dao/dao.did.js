export const idlFactory = ({ IDL }) => {
  const NeuronStatus = IDL.Variant({
    'Dissolved' : IDL.Record({ 'dissolve_delay' : IDL.Int, 'time' : IDL.Int }),
    'Locked' : IDL.Record({ 'dissolve_delay' : IDL.Int, 'time' : IDL.Int }),
    'Dissolving' : IDL.Record({ 'dissolve_delay' : IDL.Int, 'time' : IDL.Int }),
  });
  const Neuron = IDL.Record({
    'id' : IDL.Nat,
    'status' : NeuronStatus,
    'dissolve_delay' : IDL.Int,
    'createTime' : IDL.Int,
    'token_staking' : IDL.Int,
  });
  const Proposal = IDL.Record({
    'startTime' : IDL.Int,
    'endTime' : IDL.Int,
    'name' : IDL.Text,
    'vote' : IDL.Record({ 'reject' : IDL.Float64, 'accept' : IDL.Float64 }),
    'state' : IDL.Bool,
  });
  const Vote = IDL.Record({
    'principal' : IDL.Principal,
    'v_type' : IDL.Bool,
    'v_power' : IDL.Float64,
  });
  const Self = IDL.Service({
    'create_neuron' : IDL.Func(
        [IDL.Principal, IDL.Int, IDL.Int],
        [IDL.Variant({ 'Ok' : Neuron, 'Err' : IDL.Text })],
        [],
      ),
    'delete_newron' : IDL.Func([IDL.Principal], [], []),
    'dissolve_neuron' : IDL.Func(
        [IDL.Principal],
        [IDL.Variant({ 'Ok' : Neuron, 'Err' : IDL.Text })],
        [],
      ),
    'getPrincipal' : IDL.Func([], [IDL.Text], []),
    'get_all_neurons' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Principal, Neuron))],
        ['query'],
      ),
    'get_all_proposals' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(IDL.Nat, Proposal))],
        ['query'],
      ),
    'get_neuron' : IDL.Func(
        [IDL.Principal],
        [IDL.Variant({ 'Ok' : Neuron, 'Err' : IDL.Text })],
        ['query'],
      ),
    'get_proposal' : IDL.Func([IDL.Nat], [IDL.Opt(Proposal)], ['query']),
    'get_votes' : IDL.Func([IDL.Nat], [IDL.Opt(IDL.Vec(Vote))], []),
    'get_voting_power' : IDL.Func(
        [IDL.Principal],
        [
          IDL.Record({
            'age' : IDL.Float64,
            'dissolve_delay' : IDL.Float64,
            'vote_power' : IDL.Float64,
            'token_num' : IDL.Float64,
          }),
        ],
        ['query'],
      ),
    'submit_proposal' : IDL.Func(
        [Proposal],
        [IDL.Variant({ 'Ok' : Proposal, 'Err' : IDL.Text })],
        [],
      ),
    'update_neuron' : IDL.Func([IDL.Principal, Neuron], [Neuron], []),
    'vote' : IDL.Func(
        [IDL.Principal, IDL.Nat, IDL.Bool],
        [
          IDL.Variant({
            'Ok' : IDL.Tuple(IDL.Float64, IDL.Float64),
            'Err' : IDL.Text,
          }),
        ],
        [],
      ),
  });
  return Self;
};
export const init = ({ IDL }) => { return []; };
