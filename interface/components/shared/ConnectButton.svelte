<script>
  import { principal, ledgerActor } from "../../stores"
  import { plugConnection } from "../connexion"
  import { get } from "svelte/store"
  import { Principal } from "@dfinity/principal"

  export let message = "Sign in"


  async function getBalance() {
    
    if (!principal) {
      return 
    }
    let ledger = get(ledgerActor)
    if (!ledger) {
      return 
    }
    let res = await ledger.icrc1_balance_of({
      owner : get(principal),
      subaccount : []
    })
    console.log(res)
    return res / BigInt(100000000);
  }
</script>

{#if $principal}
    {#await getBalance()}
    <h1 class="slogan">Loading...</h1>
    {:then res}
    <p style="color: white">
      Login successfully! Current balances: {res} MB token
    </p>
    {:catch error}
      <p style="color: red">{error.message}</p>
    {/await}
{:else}
  <button on:click={() => plugConnection()}> {message} </button>
{/if}

