--Bloody Ritual of Cruelty
local s,id=GetID()
function s.initial_effect(c)
	-- Option 1: Ritual Summon from your hand or GY, Tributing monsters from your hand or field
	local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_GREATER,filter=function(c) return c:IsRace(RACE_FIEND) and c:IsAttribute(ATTRIBUTE_DARK) end,location=LOCATION_HAND|LOCATION_GRAVE})
	c:RegisterEffect(e1)

	-- Option 2: Ritual Summon by reducing the Levels/Ranks of monsters on the field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetTarget(s.ritualtg)
	e2:SetOperation(s.ritualop)
	c:RegisterEffect(e2)
	--If this card is in your GY: You can add both this card and 1 card that mentions "Ritual of Light and Darkness" from your GY to your hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end
s.listed_names={5789104,5789109} --Atakhan, the Cruel and Voracious
function s.thfilter(c)
	return c:IsCode(5789104,5789109) and c:IsAbleToHand()
end
--Level of a monster, or Rank if it is an Xyz Monster
function s.val(c)
	if c:IsType(TYPE_XYZ) then return c:GetRank() end
	return c:GetLevel()
end
function s.matfilter(c)
	return c:IsFaceup() and c:IsMonster() and s.val(c)>0
end
function s.total(g)
	local t=0
	for tc in g:Iter() do t=t+s.val(tc) end
	return t
end
function s.ritual_filter(c,e,tp,total)
	return c:IsRace(RACE_FIEND) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsType(TYPE_RITUAL)
		and c:GetLevel()>0 and c:GetLevel()<=total
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end
function s.ritualtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		return #mg>0 and Duel.IsExistingMatchingCard(s.ritual_filter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp,s.total(mg))
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
end
function s.ritualop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ritual_filter),tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp,s.total(mg)):GetFirst()
	if not rc then return end
	local rem=rc:GetLevel()
	local used={}
	local chosen=Group.CreateGroup()
	--pick any number of monsters and distribute the reduction until it equals the Ritual Monster's Level
	while rem>0 do
		local pool=mg-chosen
		if #pool==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=pool:Select(tp,1,1,nil):GetFirst()
		local others=s.total(pool)-s.val(tc)
		local maxv=math.min(rem,s.val(tc))
		local minv=math.max(1,rem-others)
		if minv>maxv then return end
		local amt=minv
		if maxv>minv then
			local opts={}
			for i=minv,maxv do table.insert(opts,i) end
			amt=Duel.AnnounceNumber(tp,table.unpack(opts))
		end
		chosen:AddCard(tc)
		used[tc]=amt
		rem=rem-amt
	end
	local sendg=Group.CreateGroup()
	for tc,amt in pairs(used) do
		if amt>=s.val(tc) then
			--reduced to 0: sent to the GY
			sendg:AddCard(tc)
		else
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(tc:IsType(TYPE_XYZ) and EFFECT_UPDATE_RANK or EFFECT_UPDATE_LEVEL)
			e1:SetValue(-amt)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
			tc:RegisterEffect(e1)
		end
	end
	if #sendg>0 then Duel.SendtoGrave(sendg,REASON_EFFECT) end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.BreakEffect()
	if Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
		rc:CompleteProcedure()
	end
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,c) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,c)
	if #g>0 then
		g:AddCard(c)
		Duel.HintSelection(g)
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end
