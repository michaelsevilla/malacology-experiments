metrics = {"auth.meta_load", "all.meta_load", "req_rate", "queue_len", "cpu_load_avg", "cpu_load_inst", "programmable"}

-- Metric for balancing is the workload; also dumps metrics
function mds_load()
  m = "METRICS: < "
  for i=1, #metrics do
    m = m..metrics[i].." "
  end
  BAL_LOG(0, m..">")
  for i=0, #mds do
    s = "MDS"..i..": < "
    for j=1, #metrics do
      s = s..mds[i][metrics[j]].." "
    end
    mds[i]["load"] = mds[i]["all.meta_load"]
    BAL_LOG(0, s.."> load="..mds[i]["load"])
  end
end

-- Shed load when you have load and your neighbor doesn't
function when()
  i = whoami + 1
  while i <= #mds do
    my_load = mds[whoami]["load"]
    his_load = mds[i]["load"]
    his_prog = mds[i]["programmable"]
    if my_load > 0.01 and his_load < 0.01 and his_prog < 10 then
      BAL_LOG(0, "when: GO! i="..i.." my_load="..my_load.." hisload="..his_load.." prog="..his_prog)
      sendto = i
      return true
    end
    BAL_LOG(0, "when: NOPE! i="..i.." my_load="..my_load.." hisload="..his_load.." prog="..his_prog)
    i = i + 1
  end
  return false
end

-- Shed half your load to your neighbor
-- neighbor=whoami+2 because Lua tables are indexed starting at 1
function where()
  targets = {}
  for i=1, #mds+1 do
    targets[i] = 0
  end

  BAL_LOG(0, "where: trying to sendto="..sendto)
  targets[sendto + 1] = mds[whoami]["load"]/3
  return targets
end

sendto = 0
mds_load()
if when() then
  return where()
end

targets = {}
for i=1, #mds+1 do
  targets[i] = 0
end
return targets