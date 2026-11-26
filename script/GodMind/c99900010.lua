--GodMind Processing Universe
--1) Continuous: while this card is face-up on your field, every Ignition Effect of your face-up Fusion / Synchro / Xyz / Link "GodMind"
--   monsters gets a Quick Effect clone, so those effects can also be activated at Quick Effect speed.
--   (GodMind Extra Deck monsters just write a normal Ignition Effect; this card makes the Quick version.)
--   (Briefly changed to "originally GodMind monsters only" on 2026-11-24 and reverted on 2026-11-25 at the user's request.)
--2) Once per turn, if you control 3 or more "GodMind" monsters: Set 1 Spell/Trap from either GY to your field and hijack it.
--
--Old version with counters and the 3 / 6 / 9 / 10 / 11 tiers: old_c99900010_counter_tiers.txt (same folder).
local s,id=GetID()
--"GodMind StarWare" holds the hijack code (treat a card as GodMind + rewrite its archetype / name references)
local starware=Duel.LoadCardScript(99900011)
local SET_GODMIND=0x1650
local EXTRA_TYPES=TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--Ignition Effects of your Fusion / Synchro / Xyz / Link "GodMind" monsters also get a Quick Effect clone
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ADJUST)
	e1:SetRange(LOCATION_FZONE)
	e1:SetOperation(s.cloneop)
	c:RegisterEffect(e1)
	--Once per turn, if you control 3+ "GodMind" monsters: Set 1 Spell/Trap from either GY to your field and hijack it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end
---------------------------------------------------------------------------------------------------------------------
--1) Quick Effect clones.
--The clone is a copy of the Ignition Effect with type Quick Effect / EVENT_FREE_CHAIN. It keeps the original's target, operation,
--cost, properties and once-per-turn limit (same count code, so the two share one use when the original uses "SetCountLimit(1,id)"),
--and it can only be used while a face-up, non-negated "GodMind Processing Universe" is in its controller's Field Zone.
--Every original effect is cloned once (remembered in "cloned"). If a card's effects are rebuilt (e.g. it gets hijacked),
--the new effects are new objects and get cloned too.
local cloned={}
function s.active(tp)
	local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
	return fc~=nil and fc:IsFaceup() and fc:IsCode(id) and not fc:IsDisabled()
end
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_GODMIND) and c:IsType(EXTRA_TYPES)
end
function s.makeclone(tc,te)
	local cond=te:GetCondition()
	local ce=te:Clone()
	ce:SetType(EFFECT_TYPE_QUICK_O)
	ce:SetCode(EVENT_FREE_CHAIN)
	ce:SetCondition(function(e,...)
		return s.active(e:GetHandlerPlayer()) and (not cond or cond(e,...))
	end)
	tc:RegisterEffect(ce,true)
	--while this card is active the original Ignition version cannot be activated, so there is only ever one prompt (the Quick one);
	--if this card leaves the field / is negated, the original works as normal again
	te:SetCondition(function(e,...)
		return not s.active(e:GetHandlerPlayer()) and (not cond or cond(e,...))
	end)
end
function s.cloneop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	for tc in g:Iter() do
		for _,te in ipairs{tc:GetCardEffect()} do
			if te:GetOwner()==tc and te:IsHasType(EFFECT_TYPE_IGNITION) and not cloned[te] then
				cloned[te]=true
				s.makeclone(tc,te)
			end
		end
	end
end
---------------------------------------------------------------------------------------------------------------------
--2) Set 1 Spell/Trap from either GY to your field and hijack it (it becomes a "GodMind" card and its archetype / card-name /
--Attribute / Type references are rewritten, exactly like "GodMind StarWare" does)
function s.gmfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsSetCard(SET_GODMIND)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetMatchingGroupCount(s.gmfilter,tp,LOCATION_MZONE,0,nil)>=3
end
function s.sfilter(c,tp)
	return c:IsSpellTrap() and c:IsSSetable(true)
		and (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0)
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.sfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local tc=Duel.SelectMatchingCard(tp,s.sfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,tp):GetFirst()
	if tc and Duel.SSet(tp,tc,tp)>0 and tc:IsLocation(LOCATION_ONFIELD) and tc:IsControler(tp) then
		starware.hijack(e:GetHandler(),tc)
	end
end
