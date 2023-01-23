import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Neuron {
  'id' : bigint,
  'status' : NeuronStatus,
  'dissolve_delay' : bigint,
  'createTime' : bigint,
  'token_staking' : bigint,
}
export type NeuronStatus = {
    'Dissolved' : { 'dissolve_delay' : bigint, 'time' : bigint }
  } |
  { 'Locked' : { 'dissolve_delay' : bigint, 'time' : bigint } } |
  { 'Dissolving' : { 'dissolve_delay' : bigint, 'time' : bigint } };
export interface Proposal {
  'startTime' : bigint,
  'endTime' : bigint,
  'name' : string,
  'vote' : { 'reject' : number, 'accept' : number },
  'state' : boolean,
}
export interface Self {
  'create_neuron' : ActorMethod<
    [Principal, bigint, bigint],
    { 'Ok' : Neuron } |
      { 'Err' : string }
  >,
  'delete_newron' : ActorMethod<[Principal], undefined>,
  'dissolve_neuron' : ActorMethod<
    [Principal],
    { 'Ok' : Neuron } |
      { 'Err' : string }
  >,
  'getPrincipal' : ActorMethod<[], string>,
  'get_all_neurons' : ActorMethod<[], Array<[Principal, Neuron]>>,
  'get_all_proposals' : ActorMethod<[], Array<[bigint, Proposal]>>,
  'get_neuron' : ActorMethod<
    [Principal],
    { 'Ok' : Neuron } |
      { 'Err' : string }
  >,
  'get_proposal' : ActorMethod<[bigint], [] | [Proposal]>,
  'get_votes' : ActorMethod<[bigint], [] | [Array<Vote>]>,
  'get_voting_power' : ActorMethod<
    [Principal],
    {
      'age' : number,
      'dissolve_delay' : number,
      'vote_power' : number,
      'token_num' : number,
    }
  >,
  'submit_proposal' : ActorMethod<
    [Proposal],
    { 'Ok' : Proposal } |
      { 'Err' : string }
  >,
  'update_neuron' : ActorMethod<[Principal, Neuron], Neuron>,
  'vote' : ActorMethod<
    [Principal, bigint, boolean],
    { 'Ok' : [number, number] } |
      { 'Err' : string }
  >,
}
export interface Vote {
  'principal' : Principal,
  'v_type' : boolean,
  'v_power' : number,
}
export interface _SERVICE extends Self {}
