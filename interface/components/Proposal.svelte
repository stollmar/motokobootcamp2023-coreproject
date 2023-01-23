<script>
  export let post

  function getCssColorState(state, endtime, voteAccept, voteReject) {
    if (state == false) {
      // proposal vote end
        // proposal accept = green
        if (voteAccept >= 100) {
          return "green"
        }
        if (voteReject >= 100) {
          return "brown"
        }
        if (Date.now() >= endtime && voteAccept >= voteReject) {
          return "green"
        }
        return "brown"
    }
    // proposal allow to vote
    return "black"
  }

  function getDateTime(time) {
    var date = new Date(Number(time))
    let formattedTime = "Date: "+date.getDate()+
          "/"+(date.getMonth()+1)+
          "/"+date.getFullYear()+
          " "+date.getHours()+
          ":"+date.getMinutes()+
          ":"+date.getSeconds();
    return formattedTime
  }
</script>

<div class="post-preview" style="background-color: {getCssColorState(post[1].state, post[1].endTime, post[1].vote.accept, post[1].vote.reject)};">
  <h2>Proposal Id : {post[0]}</h2>
  <p>{post[1].name}</p>
  <p>Start time: {getDateTime(post[1].startTime)}</p>
  <p>End time: {getDateTime(post[1].endTime)}</p>
  <p>Status: {post[1].state === true ? "Open to vote" : "Closed"}</p>
  <p>Change website text to: {post[1].name}</p>
  <p>
    Yes: {post[1].vote.accept}, No: {post[1].vote.reject}
  </p>
</div>

<style>
  .post-preview {
    border: 1px solid white;
    border-radius: 10px;
    margin-bottom: 2vmin;
    padding: 2vmin;
  }
  h2 {
    color: white;
  }

  p {
    color: white;
  }
</style>
