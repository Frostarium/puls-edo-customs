--GodMind Processor 10² Shi'arWare   (upgraded Pendulum version of "GodMind Shi'arWare"; Lv9 Synchro Pendulum, Pendulum Scale 10)
--[ Pendulum Effect ] During your Main Phase: You can banish 1 "GodMind" monster from your GY; Special Summon 1 Level 4 "GodMind" monster from your hand or Deck.
--  You can only use this effect of "GodMind Processor 10² Shi'arWare" once per turn.      (placeholder effect, not picked by the user)
--[ Monster Effect ] 1 Tuner + 1 "GodMind" Synchro Monster
--  You can treat 1 "GodMind" Tuner you control as Level 1 for the Synchro Summon of this card (Level 1 Tuner + Shi'arWare Lv8 = Lv9; modelled on Cupsie*Yummy Way).
--  If this card is Special Summoned: choose up to 2 other "GodMind" monsters in your hand / field / GY / banishment; apply 1 of the effects of each, ignoring costs and conditions.
--  Ignition: banish any number of monsters from your hand, field and/or either GY, and/or shuffle any number of your banished monsters into the Deck; Special Summon 1 Fusion / Synchro / Xyz / Link
--    Monster from your Extra Deck whose Level / Rank / Link Rating is <= the total (a non-Link monster counts as 1 towards a Link Monster), as that Summon, then hijack it. (Quick Effect via Processing Universe.)
--  NO "treated as Level 4 for Xyz" / "2 Link materials" passives (removed on purpose).
local s,id=GetID()
local SET_GODMIND=0x1650
--"GodMind StarWare" holds the hijack code; "GodMind Shi'arWare" holds the effect-borrowing helpers (cpfilter / efflist)
local starware=Duel.LoadCardScript(99900011)
local shiar=Duel.LoadCardScript(99900015)
function s.initial_effect(c)
	c:EnableReviveLimit()
	--must first be properly Summoned (or Pendulum Summoned, or Special Summoned by its own effect), or Special Summoned by "GodMind Computer Superprocess"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	Pendulum.AddProcedure(c,false)
	--Synchro Summon: 1 Tuner + 1 "GodMind" Synchro Monster
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(s.synfilter),1,1)
	--For this card's Synchro Summon, you can treat 1 "GodMind" Tuner you control as Level 1
	--The value function only knows the Synchro monster being Summoned, not the Tuner it is asked about, so it cannot say "no change" for other
	--Synchro Summons (returning -1 there, as "Cupsie*Yummy Way" does for Link-1 monsters that have no Level, broke every other Synchro Summon that
	--used a GodMind Tuner: it made a Level 4 Tuner unusable). So one effect per natural Level: for any other Synchro monster it returns the Tuner's own Level,
	--for this card it returns "Level 1 or its own Level" (low 16 bits = own Level, high 16 bits = 1).
	for lv=2,12 do
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_FIELD)
		e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE)
		e0:SetCode(EFFECT_SYNCHRO_LEVEL)
		e0:SetRange(LOCATION_EXTRA)
		e0:SetTargetRange(LOCATION_MZONE,0)
		e0:SetTarget(function(e,tc) return tc:IsSetCard(SET_GODMIND) and tc:IsType(TYPE_TUNER) and tc:GetLevel()==lv end)
		e0:SetValue(function(e,sc) return sc==e:GetHandler() and (lv|(1<<16)) or lv end)
		c:RegisterEffect(e0)
	end
	--Pendulum Effect: banish 1 "GodMind" monster from your GY; Special Summon 1 Level 4 "GodMind" monster from your hand or Deck
	local ep=Effect.CreateEffect(c)
	ep:SetDescription(aux.Stringid(id,3))
	ep:SetCategory(CATEGORY_SPECIAL_SUMMON)
	ep:SetType(EFFECT_TYPE_IGNITION)
	ep:SetRange(LOCATION_PZONE)
	ep:SetCountLimit(1,{id,2})
	ep:SetCost(s.pcost)
	ep:SetTarget(s.ptg)
	ep:SetOperation(s.pop)
	c:RegisterEffect(ep)
	--If Special Summoned: apply 1 effect of each of up to 2 other "GodMind" monsters
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,0})
	e3:SetTarget(s.cptg)
	e3:SetOperation(s.cpop)
	c:RegisterEffect(e3)
	--Ignition: banish / shuffle monsters, Special Summon an Extra Deck monster up to their total rating, hijack it
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end
function s.synfilter(c)
	return c:IsSetCard(SET_GODMIND) and c:IsType(TYPE_SYNCHRO)
end
---------------------------------------------------------------------------------------------------------------------
--Pendulum Effect
function s.pcostfilter(c)
	return c:IsSetCard(SET_GODMIND) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.pspfilter(c,e,tp)
	return c:IsSetCard(SET_GODMIND) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.pcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.pcostfilter),tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.pcostfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.ptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.pspfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_DECK)
end
function s.pop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.pspfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
---------------------------------------------------------------------------------------------------------------------
--If Special Summoned: apply 1 effect of each of up to 2 other "GodMind" monsters.
--Same technique as "GodMind Shi'arWare" (the chosen effect's target and operation run with THIS effect, costs and conditions skipped),
--but for 2 monsters: each chosen effect's targets are remembered separately and put back before its operation runs.
local LOC_COPY=LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED
local copied=nil
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(shiar.cpfilter,tp,LOC_COPY,0,1,c,e,tp,eg,ep,ev,re,r,rp) end
	copied={}
	local used=Group.FromCards(c)
	local cat,prop=0,EFFECT_FLAG_DELAY
	local alltg=Group.CreateGroup()
	for i=1,2 do
		if not Duel.IsExistingMatchingCard(shiar.cpfilter,tp,LOC_COPY,0,1,used,e,tp,eg,ep,ev,re,r,rp) then break end
		if i==2 and not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then break end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		local tc=Duel.SelectMatchingCard(tp,shiar.cpfilter,tp,LOC_COPY,0,1,1,used,e,tp,eg,ep,ev,re,r,rp):GetFirst()
		if not tc then break end
		used:AddCard(tc)
		local list=shiar.efflist(tc,e,tp,eg,ep,ev,re,r,rp)
		local te=list[1]
		if #list>1 then
			local opts={}
			for _,t in ipairs(list) do
				local d=t:GetDescription()
				table.insert(opts,{true,d~=0 and d or aux.Stringid(id,0)})
			end
			te=list[Duel.SelectEffect(tp,table.unpack(opts))]
		end
		cat=cat|te:GetCategory()
		prop=prop|te:GetProperty()
		e:SetProperty(prop|EFFECT_FLAG_DELAY)
		e:SetCategory(cat)
		Duel.ClearTargetCard()
		local tg=te:GetTarget()
		if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
		local tgs=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
		local rec={te=te,tg=(tgs and tgs:Clone() or Group.CreateGroup())}
		table.insert(copied,rec)
		alltg:Merge(rec.tg)
	end
	e:SetCategory(cat)
	e:SetProperty(prop|EFFECT_FLAG_DELAY)
	Duel.ClearTargetCard()
	if #alltg>0 then Duel.SetTargetCard(alltg) end
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local list=copied
	copied=nil
	if not list then return end
	for _,rec in ipairs(list) do
		local op=rec.te:GetOperation()
		if op then
			Duel.ClearTargetCard()
			if #rec.tg>0 then Duel.SetTargetCard(rec.tg) end
			op(e,tp,eg,ep,ev,re,r,rp)
		end
	end
end
---------------------------------------------------------------------------------------------------------------------
--Ignition: banish monsters from your hand / field / either GY, and/or shuffle your banished monsters into the Deck;
--Special Summon an Extra Deck monster of up to their total Level / Rank / Link Rating (Fusion Monsters included)
function s.sumtype(c)
	if c:IsType(TYPE_FUSION) then return SUMMON_TYPE_FUSION end
	if c:IsType(TYPE_SYNCHRO) then return SUMMON_TYPE_SYNCHRO end
	if c:IsType(TYPE_XYZ) then return SUMMON_TYPE_XYZ end
	if c:IsType(TYPE_LINK) then return SUMMON_TYPE_LINK end
	return nil
end
--what one monster counts for: its Link Rating, Rank or Level; towards a Link Monster a non-Link monster counts as 1
function s.rating(c,forlink)
	if c:IsLinkMonster() then return c:GetLink() end
	if forlink then return 1 end
	if c:IsType(TYPE_XYZ) then return c:GetRank() end
	return c:GetLevel()
end
function s.edfilter(c,e,tp,mat)
	local st=s.sumtype(c)
	if not st then return false end
	local link=c:IsLinkMonster()
	local size=link and c:GetLink() or (c:IsType(TYPE_XYZ) and c:GetRank() or c:GetLevel())
	local total=0
	for mc in mat:Iter() do total=total+s.rating(mc,link) end
	--a plain Special Summon (st=0), like "GodMind Shi'arWare": the "GodMind Processor 10²" monsters can only be Summoned by their own procedure,
	--a Pendulum Summon or "GodMind Computer Superprocess", and their Summoning condition rejects a plain Special Summon, so they are never offered here
	return size>0 and size<=total and Duel.GetLocationCountFromEx(tp,tp,mat,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rescon(sg,e,tp,mg)
	return Duel.IsExistingMatchingCard(s.edfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,sg),false
end
function s.fincon(sg,e,tp,mg)
	return (s.rescon(sg,e,tp,mg))
end
--banished monsters are shuffled into the Deck (they cannot be banished again), everything else is banished
function s.rmfilter(c)
	if not c:IsMonster() then return false end
	if c:IsLocation(LOCATION_REMOVED) then return c:IsFaceup() and c:IsAbleToDeckAsCost() end
	return c:IsAbleToRemoveAsCost() and (c:IsLocation(LOCATION_HAND|LOCATION_GRAVE) or c:IsFaceup())
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.rmfilter),tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED,LOCATION_GRAVE,c)
	if chk==0 then return #g>0 and aux.SelectUnselectGroup(g,e,tp,1,nil,s.rescon,0) end
	local mat=aux.SelectUnselectGroup(g,e,tp,1,nil,s.rescon,1,tp,HINTMSG_REMOVE,s.fincon)
	local sg=mat:Filter(Card.IsLocation,nil,LOCATION_REMOVED)
	local bg=mat-sg
	if #bg>0 then Duel.Remove(bg,POS_FACEUP,REASON_COST) end
	if #sg>0 then Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_COST) end
	mat:KeepAlive()
	e:SetLabelObject(mat)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mat=e:GetLabelObject()
	if not mat then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.edfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mat):GetFirst()
	if sc then
		--hijacked BEFORE it is Summoned (its own "when Special Summoned" trigger must be the rewritten one), LIGHT + Cyberse
		starware.hijack(c,sc)
		starware.lightform(c,sc)
		sc:SetMaterial(mat)
		--a plain Special Summon: not a Fusion / Synchro / Xyz / Link Summon, so no CompleteProcedure
		Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
	end
	mat:DeleteGroup()
	e:SetLabelObject(nil)
end

--Summoning condition: only by its own Summon procedure (SYNCHRO Summon), a Pendulum Summon, its own effect, or "GodMind Computer Superprocess" (99900022)
function s.splimit(e,se,sp,st)
	if se then
		local sc=se:GetHandler()
		if sc==e:GetHandler() or sc:GetOriginalCode()==99900022 then return true end
	end
	return (st&SUMMON_TYPE_SYNCHRO)==SUMMON_TYPE_SYNCHRO or (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end
