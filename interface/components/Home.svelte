<script>
  import logo from ".././assets/camp_logo.png"
  import ConnectButton from ".././components/shared/ConnectButton.svelte"
  import { principal, ledgerActor, daoActor } from "../stores"
  import { Principal } from "@dfinity/principal"
  import { get } from "svelte/store"

  let periods = [
		{ id: 0, text: `6 months` },
		{ id: 1, text: `1 years` },
		{ id: 2, text: `2 years` },
    { id: 3, text: `3 years` },
		{ id: 4, text: `4 years` },
    { id: 5, text: `5 years` },
		{ id: 6, text: `6 years` },
    { id: 7, text: `7 years` },
		{ id: 8, text: `8 years` }
	];
  let selected;
  let tokens = 100;

  let promise = getNeuron()
  let sendTokenState = false

  function handleSubmit() {
		alert(`${selected.id} You staking (${selected.text})"`);
	}

  async function transferMB() {
    if (!principal) {
      return 0
    }
    let ledger = get(ledgerActor)
    if (!ledger) {
      return 0
    }
    let params = {
      amount: tokens * 100000000,
      created_at_time: [Date.now() * 1_000_000],
      fee: [1_000_000],
      from_subaccount: Array.from(new ArrayBuffer(0)),
      memo: [],
      to: {
        owner: Principal.fromText("uyc5q-dqaaa-aaaak-aaima-cai"),
        subaccount: Array.from(new ArrayBuffer(0))
      },
    }
    // console.log(params)
    sendTokenState = true
    let res = await ledger.icrc1_transfer(params)
    // console.log(res)
    if (res.ok) {
      return res.ok
    }
    return 0
  }

  async function dissolveNeuron() {
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }
    let res = await dao.dissolve_neuron(get(principal))
    console.log(res)
    promise = getNeuron()
  }

  async function getNeuron() {
    
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }
    // Principal.fromText("2vxsx-fae")
    let res = await dao.get_neuron(get(principal))
    console.log(res)
    if (res.Ok) {
      return res.Ok
    } else {
      throw new Error(res.Err)
    }
    return res;
  }

  async function createNeuron() {
    if (!principal) {
      return 
    }
    let dao = get(daoActor)
    if (!dao) {
      return 
    }

    let x = await transferMB()
    if (x <= 0) {
      return
    }
    let tx = await getTransactions(x)
    if (tx == null) {
      return
    }
    console.log("tx found tx id=" + x)
    let dissolve_delay = 24 * 60 * 60 * 1000
    if (selected.id === 0) {
      dissolve_delay = dissolve_delay * 182
    } else {
      dissolve_delay = dissolve_delay * (365 * selected.id)
    }
    let res = await dao.create_neuron(get(principal), tokens, dissolve_delay)
    sendTokenState = false
    console.log(res)
    promise = getNeuron()
    return res;
    
  }

  async function getTransactions(txIndex) {
    if (!principal) {
      return null
    }
    let ledger = get(ledgerActor)
    if (!ledger) {
      return null
    }
    let start = 0;
    let length = 200;
    let res = await ledger.get_transactions({
      length: length,
      start: start
    })
    console.log(res.first_index)
    console.log(res.log_length)
    let total_mint = BigInt(0);
    while (res.log_length > 0) {
      console.log("log length = " + res.log_length)
      for (const x of res.transactions) {
          
          var dateFormat = new Date(Number(BigInt(x.timestamp) / BigInt(1000000)));
          if (x.kind === 'TRANSFER' && x.index === txIndex && x.transfer[0].from.owner.toString() === get(principal).toText()) {
            // console.log(x.index)
            // console.log(x)
            // console.log(x.kind)
            // console.log(x.transfer[0].amount)
            // console.log(x.transfer[0].from.owner.toString())
            // console.log(x.transfer[0].to.owner.toString())
            // console.log(dateFormat)
            return x
          }

          // if (x.kind === 'MINT' && x.mint[0].to.owner.toString() === get(principal).toText()) {
          //   console.log(x.index)
          //   console.log(x)
          //   console.log(x.kind)
          //   console.log(x.mint[0].amount)
          //   console.log(x.mint[0].to)
          //   console.log(x.mint[0].to.owner.toString())
          //   console.log(dateFormat)
          //   total_mint += x.mint[0].amount
          // }
      }
      start = start + 200;
      length = length + 200;
      res = await ledger.get_transactions({
        length: length,
        start: start
      })
    }
    return null;
  }

  function getNeuronStatus(stt) {
    if (stt['Locked'] !== undefined) {
      return "Locked"
    }
    if (stt['Dissolving'] !== undefined) {
      return "Dissolving"
    }
    return "Dissolved"
  }

  function dissolveDelayToDateFmt(dissolve_delay) {
    let y = dissolve_delay / BigInt(24 * 60 * 60 * 1000) / BigInt(365);
    let m = dissolve_delay / BigInt(24 * 60 * 60 * 1000) % BigInt(365);
    return y + (y > 1 ? " years " : " year ") + m + (m > 1 ? " months" : " month")
  }

  function getDateTime(time) {
    var date = new Date(Number(time))
    let formattedTime = date.getDate()+
          "/"+(date.getMonth()+1)+
          "/"+date.getFullYear()+
          " "+date.getHours()+
          ":"+date.getMinutes()+
          ":"+date.getSeconds();
    return formattedTime
  }
</script>

<div>
  <header class="App-header">
    <img src={logo} class="App-logo" alt="logo" />
    <p class="slogan">Motoko Bootcamp Dao</p>
    <p class="twitter">← Open me!</p>
    <ConnectButton />

    {#if $principal}
        {#await promise}
        <h1 class="slogan">Loading...</h1>
        {:then res}
        <p style="color: white">
          Has a neuron!
        </p>

          <form id="form" on:submit|preventDefault={dissolveNeuron} >
            <fieldset>
              <legend>Neuron</legend>
              <table style="border:1px">
                  <tr>
                    <td>id</td><td>{res.id}</td>
                  </tr>
                  <tr>
                    <td>Token amount:</td><td>{res.token_staking}</td>
                  </tr>
                  <tr>
                    <td>Dissolve Delay:</td><td>{dissolveDelayToDateFmt(res.dissolve_delay)}</td>
                  </tr>
                  <tr>
                    <td>Create time:</td><td>{getDateTime(res.createTime)}</td>
                  </tr>
                  
                  <tr>
                    <td>Status:</td><td>{getNeuronStatus(res.status)}</td>
                  </tr>
                 
              </table>
            </fieldset>
            {#if getNeuronStatus(res.status) == 'Locked'}
            <div class="btn__wrapper">
              <button type="submit" id="form__btn" class="btn btn2">Dissolve Neuron</button>
            </div>
            {/if}
          </form>
        <!-- <p style="color: white">
          transactions: {getTransactions()}
        </p> -->
        {:catch error}
          <!-- {#await getTransactions()}
          <h1 class="slogan">Loading...</h1>
          {:then res1}
          {:catch error}
            <p style="color: red">{error.message}</p>
          {/await} -->

            <form on:submit|preventDefault={createNeuron} style="background-color: yellowgreen;">
              <div>
                <fieldset>
                  <legend>Create Neuron</legend>
                  <table style="border:1px">
                      <tr>
                        <td>Token amount:</td><td><input type="number" bind:value={tokens}></td>
                      </tr>
                      <tr>
                        <td>Period</td><td><select bind:value={selected} on:change="{() => tokens = 0}">
                          {#each periods as period}
                            <option value={period}>
                              {period.text}
                            </option>
                          {/each}
                        </select></td>
                      </tr>
                  </table>
                </fieldset>
                <div>
                  <button disabled={tokens === 0 || sendTokenState} type=submit>
                    <span>Create newron</span>
                  </button>
                </div>
              </div>
            </form>
          
          <p style="color: red">{error.message}</p>
        {/await}
    {/if}
  </header>
</div>

<style>
html,
body {
  padding: 0;
  margin: 0;
  height: 100%;
}
input {
  height: 15px;
  border: 0;
  outline: 1px solid;
  border-radius: 3px;
}

body {
  height: 100vh;
  width: 100vw;
  background-color:aliceblue;
  display: grid;
  place-content: center;
  gap: 0.5em;

  text-align: center;
  line-height: 1.42;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Oxygen",
    "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue",
    sans-serif;
}

form {
  background-color:white;
  display: flex;
  flex-direction: column;
  gap: 1em;
  border: 2px dotted;
  padding: 20px 10px;
}

input:invalid {
  background-color: rgb(255, 231, 231);
}

input:valid {
  background-color: rgb(224, 255, 218);
}

.group {
  display: flex;
  /* outline: 1px solid; */
  align-items: center;
  justify-content: space-between;
}
.group label {
  width: 50px;
}

fieldset {
  display: flex;
  flex-direction: column;
  border: 1px dotted;
  gap: 1em;
}

legend {
  font-weight: 600;
}

input[type="submit"] {
  height: auto;
  background-color: transparent;
  padding: 5px;
}

input[type="submit"]:hover {
  background-color: rgb(244, 244, 244);
}

</style>